import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// AI Chat Service using Google Gemini API
/// Hỗ trợ chat thông minh với AI, có memory và context
class AIChatService {
  // Google Gemini API configuration
  // User cần cung cấp API key từ: https://makersuite.google.com/app/apikey
  static String? _apiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-1.5-flash'; // Fast, free model
  
  // Conversation history for context
  static final List<Map<String, String>> _conversationHistory = [];
  static const int _maxHistoryLength = 20; // Keep last 20 messages for context
  
  /// Initialize with API key
  static void initialize(String apiKey) {
    _apiKey = apiKey;
    debugPrint('✅ AIChatService: Initialized with API key');
  }
  
  /// Check if service is initialized
  static bool get isInitialized => _apiKey != null && _apiKey!.isNotEmpty;
  
  /// Set API key
  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }
  
  /// Get API key
  static String? get apiKey => _apiKey;
  
  /// Clear conversation history
  static void clearHistory() {
    _conversationHistory.clear();
    debugPrint('🗑️ AIChatService: Conversation history cleared');
  }
  
  /// Send message to AI and get response
  static Future<AIChatResponse> sendMessage(String message) async {
    if (!isInitialized) {
      return AIChatResponse(
        success: false,
        message: 'AI Service not initialized. Please set your API key in Settings.',
        error: 'NO_API_KEY',
      );
    }
    
    try {
      // Add user message to history
      _conversationHistory.add({
        'role': 'user',
        'parts': message,
      });
      
      // Trim history if too long
      if (_conversationHistory.length > _maxHistoryLength * 2) {
        _conversationHistory.removeRange(0, 2);
      }
      
      // Build request body with conversation history
      final contents = _conversationHistory.map((msg) => {
        'role': msg['role'],
        'parts': [{'text': msg['parts']}],
      }).toList();
      
      final requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_ONLY_HIGH',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_ONLY_HIGH',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_ONLY_HIGH',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_ONLY_HIGH',
          },
        ],
      };
      
      final url = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract response text
        String aiMessage = '';
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            aiMessage = candidate['content']['parts'][0]['text'] ?? '';
          }
        }
        
        if (aiMessage.isEmpty) {
          // Check for safety block
          if (data['candidates']?[0]?['finishReason'] == 'SAFETY') {
            return AIChatResponse(
              success: false,
              message: 'I cannot respond to that message due to safety guidelines.',
              error: 'SAFETY_BLOCK',
            );
          }
          
          return AIChatResponse(
            success: false,
            message: 'I couldn\'t generate a response. Please try again.',
            error: 'EMPTY_RESPONSE',
          );
        }
        
        // Add AI response to history
        _conversationHistory.add({
          'role': 'model',
          'parts': aiMessage,
        });
        
        return AIChatResponse(
          success: true,
          message: aiMessage,
        );
      } else {
        // Handle API errors
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Unknown error';
        
        if (errorData['error'] != null) {
          errorMessage = errorData['error']['message'] ?? 'API Error';
          
          // Check for specific errors
          if (errorMessage.contains('API key')) {
            return AIChatResponse(
              success: false,
              message: 'Invalid API key. Please check your API key in Settings.',
              error: 'INVALID_API_KEY',
            );
          }
          
          if (response.statusCode == 429) {
            return AIChatResponse(
              success: false,
              message: 'Rate limit exceeded. Please wait a moment and try again.',
              error: 'RATE_LIMIT',
            );
          }
        }
        
        debugPrint('❌ AIChatService: API Error: ${response.statusCode} - $errorMessage');
        
        // Remove last user message since request failed
        if (_conversationHistory.isNotEmpty && 
            _conversationHistory.last['role'] == 'user') {
          _conversationHistory.removeLast();
        }
        
        return AIChatResponse(
          success: false,
          message: 'Failed to get response: $errorMessage',
          error: 'API_ERROR',
        );
      }
    } catch (e) {
      debugPrint('❌ AIChatService: Error: $e');
      
      // Remove last user message since request failed
      if (_conversationHistory.isNotEmpty && 
          _conversationHistory.last['role'] == 'user') {
        _conversationHistory.removeLast();
      }
      
      return AIChatResponse(
        success: false,
        message: 'Network error. Please check your internet connection.',
        error: 'NETWORK_ERROR',
      );
    }
  }
  
  /// Get suggested prompts for quick actions
  static List<String> getSuggestedPrompts() {
    return [
      '💡 Give me a creative idea',
      '📝 Help me write something',
      '🧮 Solve a math problem',
      '🌍 Tell me about a country',
      '📚 Explain a concept',
      '🎯 Give me advice',
      '🎨 Describe an image idea',
      '💻 Help with coding',
    ];
  }
  
  /// Get conversation history
  static List<Map<String, String>> get conversationHistory => 
      List.unmodifiable(_conversationHistory);
}

/// Response model for AI Chat
class AIChatResponse {
  final bool success;
  final String message;
  final String? error;
  
  AIChatResponse({
    required this.success,
    required this.message,
    this.error,
  });
}
