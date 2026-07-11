import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const NebulaApp());
}

class NebulaApp extends StatelessWidget {
  const NebulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nebula Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          surface: const Color(0xFF1E1E2C),
          background: const Color(0xFF151521),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "ai", "content": "Hey there! How can I help you today?"}
  ];
  
  bool _isGenerating = false;
  Process? _activeProcess;
  List<String> _speechQueue = [];
  bool _isSpeaking = false;
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    flutterTts.setSpeechRate(0.6);
    flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _speakNext() async {
    if (_isSpeaking || _speechQueue.isEmpty) return;
    
    _isSpeaking = true;
    final sentence = _speechQueue.removeAt(0);
    String cleanSentence = sentence.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (cleanSentence.isEmpty) {
      _isSpeaking = false;
      _speakNext();
      return;
    }
    
    flutterTts.speak(cleanSentence).then((_) {
      _isSpeaking = false;
      _speakNext();
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add({"role": "user", "content": text});
      _messages.add({"role": "ai", "content": ""});
      _isGenerating = true;
    });
    
    _controller.clear();
    String ttsBuffer = "";
    
    try {
      _activeProcess = await Process.start('python3', ['../core/brain.py', text]);
      
      _activeProcess!.stdout.transform(utf8.decoder).listen((data) {
        if (!mounted) return;
        
        String chunk = data.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
        
        ttsBuffer += chunk;
        final sentenceRegex = RegExp(r'([^.!?]+[.!?])');
        Match? match;
        while ((match = sentenceRegex.firstMatch(ttsBuffer)) != null) {
          final sentence = match!.group(0)!;
          _speechQueue.add(sentence);
          _speakNext();
          ttsBuffer = ttsBuffer.substring(match.end);
        }
        
        setState(() {
          final lastIndex = _messages.length - 1;
          _messages[lastIndex]["content"] = (_messages[lastIndex]["content"]! + chunk);
        });
      }, onDone: () {
        if (!mounted) return;
        
        if (ttsBuffer.trim().isNotEmpty) {
          _speechQueue.add(ttsBuffer.trim());
          _speakNext();
        }
        
        setState(() {
          _isGenerating = false;
          _activeProcess = null;
          final lastIndex = _messages.length - 1;
          _messages[lastIndex]["content"] = _messages[lastIndex]["content"]!.trim();
          if (_messages[lastIndex]["content"]!.isEmpty) {
            _messages[lastIndex]["content"] = "No response from AI core.";
          }
        });
      }, onError: (e) {
        if (!mounted) return;
        setState(() {
          _isGenerating = false;
          _activeProcess = null;
          final lastIndex = _messages.length - 1;
          _messages[lastIndex]["content"] = "Error: $e";
        });
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _activeProcess = null;
        final lastIndex = _messages.length - 1;
        _messages[lastIndex]["content"] = "Error: $e";
      });
    }
  }

  void _stopGeneration() async {
    _activeProcess?.kill();
    _activeProcess = null;
    _speechQueue.clear();
    _isSpeaking = false;
    await flutterTts.stop();
    setState(() {
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Nebula Companion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isUser ? colorScheme.primary : colorScheme.surface,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                        child: Text(
                          msg["content"]!,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!isUser && msg["content"]!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: IconButton(
                            icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: msg["content"]!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                              );
                            },
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      if (isUser)
                        const SizedBox(height: 12.0),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_isGenerating)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.stop, color: Colors.white, size: 24),
                          onPressed: _stopGeneration,
                        ),
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: colorScheme.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
