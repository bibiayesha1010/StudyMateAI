import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../models/chatmessage_model.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import '../services/gemini_service.dart';
import '../screens/quiz_screen.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class AIWorkspaceScreen extends StatefulWidget {
  final String email;

  final Conversation? conversation;

  const AIWorkspaceScreen({
    super.key,
    required this.email,
    this.conversation,
  });

  @override
  State<AIWorkspaceScreen> createState() => _AIWorkspaceScreenState();
}

class _AIWorkspaceScreenState extends State<AIWorkspaceScreen> {
  final TextEditingController messageController = TextEditingController();

  final GeminiService geminiService = GeminiService();

  final List<ChatMessage> messages = [];
  Conversation? currentConversation;
  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  PlatformFile? selectedPdf;
  String? selectedDocText; // extracted plain text from a .docx
  String? selectedDocName;

  // Image.file() uses dart:io, which doesn't exist on web — on web,
  // XFile paths are blob URLs, which only Image.network can load.
  // On mobile, paths are real files, which only Image.file can load.
  Widget buildImageFromPath(
    String path, {
    required double height,
    required double width,
  }) {
    if (kIsWeb) {
      return Image.network(
        path,
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(path),
      height: height,
      width: width,
      fit: BoxFit.cover,
    );
  }

  // Applies a suggestion directly to whatever's already in the input
  // (typed text and/or a selected image), instead of opening a dialog.
  void applyQuickAction(String label) {
    if (label == "Generate Quiz") {
      startQuiz();
      return;
    }

    final typed = messageController.text.trim();

    String prompt;

    if (label == "Generate Notes") {
      prompt = typed.isNotEmpty
          ? "Generate detailed study notes for $typed"
          : "Generate detailed study notes based on this.";
    } else if (label == "Explain Topic") {
      prompt = typed.isNotEmpty
          ? "Explain the topic $typed"
          : "Explain what this is about.";
    } else {
      // Summarize
      prompt = typed.isNotEmpty
          ? "Summarize the following content:\n\n$typed"
          : "Summarize this.";
    }

    messageController.text = prompt;

    sendMessage();
  }

  // Builds quiz content from the whole conversation so far (what was
  // uploaded + explained), or from typed text if that's all there is,
  // then generates a real structured quiz and opens the quiz screen.
  Future<void> startQuiz({String? topicOverride}) async {
    final typed = messageController.text.trim();

    String content;

    if (topicOverride != null && topicOverride.isNotEmpty) {
      content = topicOverride;
    } else if (typed.isNotEmpty) {
      content = typed;
    } else if (messages.isNotEmpty) {
      content = messages.map((m) => m.text).join("\n\n");
    } else {
      content = "general knowledge";
    }

    final imageForQuiz = selectedImage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final quiz = await geminiService.generateQuiz(
        content,
        image: imageForQuiz,
      );

      if (!mounted) return;

      Navigator.pop(context); // close loading dialog

      messageController.clear();
      setState(() {
        selectedImage = null;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(quiz: quiz),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't generate quiz: $e")),
      );
    }
  }

  Widget quickActionChip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Theme.of(context).cardColor,
      onPressed: () => applyQuickAction(label),
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning ☀️";
    } else if (hour < 17) {
      return "Good Afternoon 🌤";
    } else {
      return "Good Evening 🌙";
    }
  }

  void showPlusMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text("Upload Image"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text("Upload files"),
                onTap: () {
                  Navigator.pop(context);
                  pickPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Extracts plain text from a .docx file's internal XML. .docx is a
  // ZIP archive containing word/document.xml with the actual text in
  // <w:t> nodes — Gemini can't read the raw ZIP bytes as if it were
  // a PDF, so we pull the text out here instead.
  String _extractDocxText(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw Exception('Not a valid .docx file'),
    );
    final xmlContent = utf8.decode(documentFile.content as List<int>);
    final document = XmlDocument.parse(xmlContent);
    final textNodes = document.findAllElements('w:t');

    final buffer = StringBuffer();
    for (final node in textNodes) {
      buffer.write(node.innerText);
      buffer.write(' ');
    }
    return buffer.toString().trim();
  }

  Future<void> pickPdf() async {
    debugPrint("PICKER: opening...");

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      debugPrint("PICKER: cancelled or empty");
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    final ext = file.extension?.toLowerCase();

    debugPrint("PICKER FILE: name=${file.name}, ext=$ext, bytes=${bytes?.length}");

    if (bytes == null) {
      debugPrint("PICKER: bytes were null, nothing set");
      return;
    }

    if (ext == 'pdf') {
      setState(() {
        selectedPdf = file;
        selectedDocText = null;
        selectedDocName = null;
        selectedImage = null;
      });
      return;
    }

    if (ext == 'docx') {
      try {
        final extracted = _extractDocxText(bytes);

        if (extracted.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn't find any text in that Word document."),
            ),
          );
          return;
        }

        setState(() {
          selectedDocText = extracted;
          selectedDocName = file.name;
          selectedPdf = null;
          selectedImage = null;
        });
      } catch (e) {
        debugPrint("DOCX EXTRACTION ERROR: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't read that Word file: $e")),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Only PDF and .docx Word files are supported (not the older .doc format).",
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        selectedImage = image;
        selectedPdf = null;
        selectedDocText = null;
        selectedDocName = null;
      });
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    final imageToSend = selectedImage;
    final pdfToSend = selectedPdf;
    final docTextToSend = selectedDocText;
    final docNameToSend = selectedDocName;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      imagePath: imageToSend?.path,
      fileName: pdfToSend?.name ?? docNameToSend,
    );

    // Capture history BEFORE adding the new user message, so Gemini
    // sees everything that came before this turn.
    final historyForThisTurn = List<ChatMessage>.from(messages);

    setState(() {
      messages.add(userMessage);

      if (currentConversation == null) {
        currentConversation = ChatService.instance.createConversation(text);
      } else {
        ChatService.instance.addMessage(
          currentConversation!,
          userMessage,
        );
      }
    });

    messageController.clear();
    setState(() {
      selectedImage = null;
      selectedPdf = null;
      selectedDocText = null;
      selectedDocName = null;
    });

    // A .docx isn't sent as inline_data (Gemini would try to read it
    // as if it were a PDF and reject it) — its extracted text is
    // folded straight into the prompt instead.
    String finalPrompt = text;
    if (docTextToSend != null) {
      finalPrompt =
          "$text\n\n[Content from uploaded notes \"$docNameToSend\"]:\n$docTextToSend";
    }

    debugPrint("FINAL PROMPT LENGTH: ${finalPrompt.length}");

    final response = await geminiService.sendMessage(
      finalPrompt,
      image: imageToSend,
      pdfBytes: pdfToSend?.bytes,
      history: historyForThisTurn,
    );

    final aiMessage = ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      messages.add(aiMessage);

      ChatService.instance.addMessage(
        currentConversation!,
        aiMessage,
      );
    });
  }

  Future<void> exportPDF() async {
    debugPrint("PDF EXPORT STARTED");

    final pdf = pw.Document();

    final chat = messages
        .map((m) => "${m.isUser ? "You" : "AI"}: ${m.text}")
        .join("\n\n");

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Text(chat),
          );
        },
      ),
    );

    final bytes = await pdf.save();

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: "StudyMate_Chat.pdf",
          mimeType: "application/pdf",
        ),
      ],
      text: "StudyMate Chat PDF",
    );
  }

  @override
  void dispose() {
    messageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        email: widget.email,
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: "Share",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                builder: (context) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.copy),
                            title: const Text("Copy Chat"),
                            onTap: () {
                              final chat = messages
                                  .map((m) =>
                                      "${m.isUser ? "You" : "StudyMate"}: ${m.text}")
                                  .join("\n\n");

                              Clipboard.setData(
                                ClipboardData(text: chat),
                              );

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Chat copied to clipboard."),
                                ),
                              );
                            },
                          ),
                          const ListTile(
                            leading: Icon(Icons.image_outlined),
                            title: Text("Share as Image"),
                          ),
                          ListTile(
                            leading: const Icon(Icons.picture_as_pdf_outlined),
                            title: const Text("Export as PDF"),
                            onTap: () {
                              debugPrint("PDF BUTTON CLICKED");
                              Navigator.pop(context);

                              exportPDF();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.share_outlined),
                            title: const Text("Share via Apps"),
                            onTap: () {
                              final chat = messages
                                  .map((m) =>
                                      "${m.isUser ? "You" : "AI"}: ${m.text}")
                                  .join("\n\n");

                              Navigator.pop(context);

                              Share.share(
                                chat,
                                subject: "StudyMate Chat",
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.close),
                            title: const Text("Cancel"),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  getGreeting(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "How can I help you study today?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.35),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "StudyMate",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];

                        return Align(
                          alignment: message.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(
                              maxWidth: 300,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7ECF3),
                              borderRadius: BorderRadius.circular(
                                18,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (message.imagePath != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: buildImageFromPath(
                                      message.imagePath!,
                                      height: 150,
                                      width: 150,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (message.fileName != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            message.fileName!,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                const SizedBox(height: 8),
                                SelectableText(
                                  message.text,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(
              height: 1,
            ),
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: buildImageFromPath(
                          selectedImage!.path,
                          height: 100,
                          width: 100,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              selectedImage = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (selectedPdf != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    label: Text(selectedPdf!.name),
                    onDeleted: () {
                      setState(() {
                        selectedPdf = null;
                      });
                    },
                  ),
                ),
              ),
            if (selectedDocText != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(
                      Icons.description,
                      color: Colors.blue,
                    ),
                    label: Text(selectedDocName ?? "Word document"),
                    onDeleted: () {
                      setState(() {
                        selectedDocText = null;
                        selectedDocName = null;
                      });
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    quickActionChip("Generate Notes"),
                    quickActionChip("Explain Topic"),
                    quickActionChip("Summarize"),
                    quickActionChip("Generate Quiz"),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                    ),
                    onPressed: showPlusMenu,
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Ask anything...",
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.mic_none,
                    ),
                    onPressed: () {},
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                      ),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}