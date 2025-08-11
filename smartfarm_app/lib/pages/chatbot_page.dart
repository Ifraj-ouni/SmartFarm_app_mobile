import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String? _lastUserMessage; // variable pour garder la dernière question

  final String groqApiKey =
      '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'; // Remplace par ta clé Groq

  DocumentReference? _conversationRef;

  Future<void> _initConversationIfNeeded() async {
    if (_conversationRef != null) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Utilisateur non connecté");
      return; // ou gérer la redirection vers la page de login
    }
    final newConversation = await FirebaseFirestore.instance
        .collection('conversations')
        .add({
          'userId': user.uid,
          'theme': 'agriculture',
          'createdAt': FieldValue.serverTimestamp(),
        });

    setState(() {
      _conversationRef = newConversation;
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await _initConversationIfNeeded();

    setState(() {
      _messages.add({"sender": "user", "text": text});
    });

    _lastUserMessage = text; // <-- garde la question ici

    _textController.clear();

    await _sendToGroq(text); // envoie au bot
  }

  Future<void> _saveQuestionAnswer({
    required String question,
    required String answer,
  }) async {
    if (_conversationRef == null) return;

    await _conversationRef!.collection('qa').add({
      'question': question,
      'answer': answer,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendToGroq(String userMessage) async {
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $groqApiKey",
    };

    final body = jsonEncode({
      "model": "llama3-8b-8192",
      "messages": [
        {
          "role": "system",
          "content":
              "Tu es un assistant expert en agriculture. Tu réponds uniquement aux questions liées aux plantes, cultures, maladies agricoles, irrigation, fertilisation, récolte, sols, serres, élevage. Si une question n’est pas liée à l’agriculture, tu dois répondre : ' Je suis désolé, je ne réponds qu’aux questions agricoles.' Ne réponds jamais aux autres sujets.",
        },
        {"role": "user", "content": userMessage},
      ],

      "temperature": 0.7,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add({"sender": "bot", "text": content});
        });

        // Sauvegarde ici la question + réponse dans Firestore
        await _saveQuestionAnswer(
          question: _lastUserMessage ?? '',
          answer: content,
        );
      }
    } catch (e) {
      setState(() {
        _messages.add({"sender": "bot", "text": "❌ Erreur réseau : $e"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Agricole'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green[200] : Colors.orange[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration.collapsed(
                      hintText: "Écris ta question ici...",
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
