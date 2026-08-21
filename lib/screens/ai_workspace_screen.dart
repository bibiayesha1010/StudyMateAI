import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/app_drawer.dart';
import '../models/chatmessage_model.dart';
import '../models/conversation_model.dart';
import '../providers/language_provider.dart';
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
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

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
String? currentTopicContext;
XFile? selectedImage;
Uint8List? selectedImageBytes;
PlatformFile? selectedPdf;
String? selectedDocText; // extracted plain text from a .docx
String? selectedDocName;

// Speech-to-text variables
final stt.SpeechToText _speechToText = stt.SpeechToText();
bool _isListening = false;
String _recognizedText = '';

@override
void initState() {
  super.initState();

  if (widget.conversation != null) {
    currentConversation = widget.conversation;
    messages.addAll(widget.conversation!.messages);
  }
}

// Image.file() uses dart, which doesn't exist on web — on web,
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

void copyMessageText(String text) {
Clipboard.setData(ClipboardData(text: text));
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text("Copied to clipboard."),
duration: Duration(seconds: 1),
),
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

  if (typed.isNotEmpty) {
    // If the student typed something new, use that.
    if (label == "Generate Notes") {
      prompt = "Generate detailed study notes for:\n\n$typed";
    } else if (label == "Explain Topic") {
      prompt = "Explain this topic clearly:\n\n$typed";
    } else {
      prompt = "Summarize the following:\n\n$typed";
    }
  } else if (currentTopicContext != null &&
      currentTopicContext!.isNotEmpty) {
    // Otherwise use the current study topic.
    if (label == "Generate Notes") {
      prompt =
          "Generate detailed study notes based on the following current study topic and explanation:\n\n"
          "$currentTopicContext";
    } else if (label == "Explain Topic") {
      prompt =
          "Explain the current topic in more detail based on this conversation:\n\n"
          "$currentTopicContext";
    } else {
      prompt =
          "Summarize the current study topic based on this conversation:\n\n"
          "$currentTopicContext";
    }
  } else {
    // No previous topic yet.
    if (label == "Generate Notes") {
      prompt = "Generate detailed study notes.";
    } else if (label == "Explain Topic") {
      prompt = "Explain the topic being discussed.";
    } else {
      prompt = "Summarize the current conversation.";
    }
  }

  messageController.text = prompt;

  sendMessage();
}

// Builds quiz content from the whole conversation so far (what was
// uploaded + explained), or from typed text if that's all there is,
// then generates a real structured quiz and opens the quiz screen.
Future<void> startQuiz({String? topicOverride}) async {
final typed = messageController.text.trim();
final imageForQuiz = selectedImage;
final pdfBytesForQuiz = selectedPdf?.bytes;
final docTextForQuiz = selectedDocText;

String content;

if (topicOverride != null && topicOverride.isNotEmpty) {
  content = topicOverride;
} else if (typed.isNotEmpty) {
  content = typed;
} else if (imageForQuiz != null) {
  // A freshly attached image should drive the quiz, not old chat
  // history — otherwise a prior topic (e.g. photosynthesis) can
  // dominate over what was just uploaded.
  content = "Base the quiz entirely on the attached image.";
} else if (pdfBytesForQuiz != null) {
  content = "Base the quiz entirely on the attached PDF.";
} else if (docTextForQuiz != null) {
  content = docTextForQuiz;
} else if (currentTopicContext != null &&
    currentTopicContext!.isNotEmpty) {
  content = currentTopicContext!;
} else if (messages.isNotEmpty) {
  content = messages.last.text;
} else {
  content = "general knowledge";
}

showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => const Center(
    child: CircularProgressIndicator(),
  ),
);

try {
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  
  final quiz = await geminiService.generateQuiz(
    content,
    image: imageForQuiz,
    pdfBytes: pdfBytesForQuiz,
    language: languageProvider.selectedLanguage,
  );

  if (!mounted) return;

  Navigator.pop(context); // close loading dialog

  messageController.clear();
  setState(() {
    selectedImage = null;
    selectedPdf = null;
    selectedDocText = null;
    selectedDocName = null;
  });

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => QuizScreen(quiz: quiz),
    ),
  );
}catch (e, stackTrace) {

  debugPrint("QUIZ GENERATION ERROR: $e");
  debugPrint("QUIZ STACK TRACE: $stackTrace");

  if (!mounted) return;

  Navigator.pop(context); // close loading dialog

  ScaffoldMessenger.of(context).showSnackBar(

    SnackBar(
      content: Text("Quiz Error: $e"),
      duration: const Duration(seconds: 5),
    ),

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

Widget _buildGreeting() {
final hour = DateTime.now().hour;
String text;
IconData icon;
Color iconColor;

if (hour < 12) {
  text = "Good Morning";
  icon = Icons.wb_sunny;
  iconColor = Colors.amber;
} else if (hour < 17) {
  text = "Good Afternoon";
  icon = Icons.wb_sunny;
  iconColor = Colors.amber;
} else {
  text = "Good Evening";
  icon = Icons.nights_stay;
  iconColor = Colors.amber;
}

return Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      text,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(width: 8),
    Icon(
      icon,
      size: 28,
      color: iconColor,
    ),
  ],
);
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
leading: Icon(
  Icons.image_outlined,
  color: Theme.of(context).brightness == Brightness.dark
      ? Colors.amber
      : null,
),
title: const Text("Upload Image"),
onTap: () {
  Navigator.pop(context);
  pickImage();
},
),
ListTile(
leading: Icon(
  Icons.picture_as_pdf_outlined,
  color: Theme.of(context).brightness == Brightness.dark
      ? Colors.amber
      : null,
),
title: const Text("Upload Files"),
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
// <w> nodes — Gemini can't read the raw ZIP bytes as if it were
// a PDF, so we pull the text out here instead.
String _extractDocxText(Uint8List bytes) {
final archive = ZipDecoder().decodeBytes(bytes);
final documentFile = archive.files.firstWhere(
(f) => f.name == 'word/document.xml',
orElse: () => throw Exception('Not a valid .docx file'),
);
final xmlContent = utf8.decode(documentFile.content as List<int>);
final document = XmlDocument.parse(xmlContent);
final textNodes = document.findAllElements('w');

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
      const SnackBar(content: Text("StudyMate Error: Couldn't read that Word file. Please try a different file.")),
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

await ChatService.instance.persistConversations();

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

final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

final response = await geminiService.sendMessage(
  finalPrompt,
  image: imageToSend,
  pdfBytes: pdfToSend?.bytes,
  history: historyForThisTurn,
  language: languageProvider.selectedLanguage,
);

final aiMessage = ChatMessage(
  text: response,
  isUser: false,
  timestamp: DateTime.now(),
);
currentTopicContext =
    "Student: $text\n\nStudyMate: $response";
setState(() {
  messages.add(aiMessage);

  ChatService.instance.addMessage(
    currentConversation!,
    aiMessage,
  );
});

await ChatService.instance.persistConversations();

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

Future<void> _initializeSpeechToText() async {
  try {
    final available = await _speechToText.initialize(
      onError: (error) {
        debugPrint('Speech to text error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('StudyMate Error: Microphone not available. Please check your device settings.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isListening = false;
        });
      },
      onStatus: (status) {
        debugPrint('Speech to text status: $status');
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('StudyMate Error: Microphone not available on this device'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    debugPrint('Failed to initialize speech to text: $e');
  }
}

void _toggleMicrophone() async {
  if (!_isListening) {
    // Start listening
    if (!_speechToText.isAvailable) {
      await _initializeSpeechToText();
    }

    if (_speechToText.isAvailable) {
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
            messageController.text = _recognizedText;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    }
  } else {
    // Stop listening
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }
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
foregroundColor: Theme.of(context).brightness == Brightness.dark
    ? Colors.amber
    : Theme.of(context).colorScheme.onSurface,
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
leading: Icon(
  Icons.copy,
  color: Theme.of(context).brightness == Brightness.dark
      ? Colors.amber
      : null,
),
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
ListTile(
  leading: Icon(
    Icons.image_outlined,
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.amber
        : null,
  ),
  title: const Text("Share as Image"),
),
ListTile(
  leading: Icon(
    Icons.picture_as_pdf_outlined,
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.amber
        : null,
  ),
  title: const Text("Export as PDF"),
  onTap: () {
    debugPrint("PDF BUTTON CLICKED");
    Navigator.pop(context);

    exportPDF();
  },
),
ListTile(
  leading: Icon(
    Icons.share_outlined,
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.amber
        : null,
  ),
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
  leading: Icon(
    Icons.close,
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.amber
        : null,
  ),
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
            child: _buildGreeting(),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber
                            : Theme.of(context)
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber
                              : Theme.of(context)
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : const Color(0xFFE7ECF3),
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
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.red.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.red[300]
                                          : Colors.red,
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
                            // Renders Markdown (bullets, bold,
                            // headings) instead of showing raw
                            // *, ** symbols as literal text.
                            MarkdownBody(
                              data: message.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                                listBullet: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                                strong: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ),
                            // Copy button — only on AI replies,
                            // not on your own messages.
                            if (!message.isUser)
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(6),
                                  onTap: () =>
                                      copyMessageText(message.text),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                    ),
                                    child: Icon(
                                      Icons.copy_outlined,
                                      size: 16,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.amber
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
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
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber
                            : null,
                      ),
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
                avatar: Icon(
                  Icons.picture_as_pdf,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.red[300]
                      : Colors.red,
                ),
                label: Text(
                  selectedPdf!.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
                avatar: Icon(
                  Icons.description,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[300]
                      : Colors.blue,
                ),
                label: Text(
                  selectedDocName ?? "Word document",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.amber
                      : null,
                ),
                onPressed: showPlusMenu,
              ),
              Expanded(
                child: TextField(
                  controller: messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => sendMessage(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: "Ask anything...",
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening
                      ? Colors.red
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber
                          : null),
                ),
                onPressed: _toggleMicrophone,
                tooltip: _isListening ? 'Stop Recording' : 'Start Recording',
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.amber
                      : Colors.blue,
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