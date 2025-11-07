import 'dart:developer';

import 'package:dio/dio.dart';

enum Summary { huggingFace, meaningCloud, smmry, textRazor }

class AISummaryService {
  final Dio _dio = Dio();
  final Summary provider;
  final String? apiKey;

  AISummaryService({this.provider = Summary.huggingFace, this.apiKey});

  Future<String> summarizeText(String url, String text) async {
    try {
      // Trim text to reasonable length (most APIs have limits)
      final trimmedText = text.length > 5000 ? text.substring(0, 5000) : text;

      log(provider.toString());

      switch (provider) {
        case Summary.huggingFace:
          return await _summarizeWithHuggingFace(trimmedText);
        case Summary.meaningCloud:
          return await _summarizeWithMeaningCloud(trimmedText);
        case Summary.smmry:
          return await _summarizeWithSmmry(url, text);
        case Summary.textRazor:
          return await _summarizeWithTextRazor(trimmedText);
      }
    } catch (e) {
      print('Summary error: $e');
      // Fallback to simple extractive summary
      return _fallbackSummary(text);
    }
  }

  Future<String> _summarizeWithHuggingFace(String text) async {
    log('hit summarize with hugging face method');
    if (apiKey == null) {
      throw Exception('Hugging Face API key required');
    }

    try {
      final response = await _dio.post(
        'https://api-inference.huggingface.co/models/facebook/bart-large-cnn',
        data: {
          'inputs': text,
          'parameters': {
            'max_length': 150,
            'min_length': 50,
            'do_sample': false,
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      // Handle model loading state
      if (response.statusCode == 503) {
        final data = response.data;
        if (data is Map &&
            data['error']?.toString().contains('loading') == true) {
          final estimatedTime = data['estimated_time'] ?? 20;
          print('Model loading, waiting ${estimatedTime}s...');
          await Future.delayed(Duration(seconds: estimatedTime.toInt() + 5));
          return await _summarizeWithHuggingFace(text); // Retry
        }
      }

      // Handle deprecated endpoint (410 error)
      if (response.statusCode == 410) {
        print('Using fallback: Old endpoint deprecated, trying new router...');
        return await _summarizeWithHuggingFaceRouter(text);
      }

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          return data[0]['summary_text'] ?? _fallbackSummary(text);
        }
      }

      throw Exception('Hugging Face API error: ${response.statusCode}');
    } catch (e) {
      print('HF error, trying router: $e');
      // Fallback to new router endpoint
      return await _summarizeWithHuggingFaceRouter(text);
    }
  }

  // New Hugging Face Router endpoint (2024+)
  Future<String> _summarizeWithHuggingFaceRouter(String text) async {
    log('hit summarizeWithHuggingFaceRouter');
    if (apiKey == null) {
      throw Exception('Hugging Face API key required');
    }

    try {
      final response = await _dio.post(
        'https://api-inference.huggingface.co/models/Falconsai/text_summarization',
        data: {
          'inputs': text,
          'parameters': {
            'max_length': 150,
            'min_length': 30,
            'do_sample': false,
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      log(response.data.toString(), name: 'response with');

      if (response.statusCode == 503) {
        print('Model loading, waiting...');
        await Future.delayed(Duration(seconds: 20));
        return await _summarizeWithHuggingFaceRouter(text);
      }

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          final summaryText =
              data[0]['summary_text'] ?? data[0]['generated_text'];
          return summaryText ?? _fallbackSummary(text);
        }
      }

      throw Exception('HF Router API error: ${response.statusCode}');
    } catch (e) {
      print('All HF endpoints failed: $e');
      // Use fallback summary
      return _fallbackSummary(text);
    }
  }

  Future<String> _summarizeWithMeaningCloud(String text) async {
    if (apiKey == null) {
      throw Exception('MeaningCloud API key required');
    }

    final response = await _dio.post(
      'https://api.meaningcloud.com/summarization-1.0',
      data: {'key': apiKey, 'txt': text, 'sentences': '3'},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['status']['code'] == '0') {
        return data['summary'] ?? _fallbackSummary(text);
      }
    }
    log(response.data.toString(), name: 'response data');

    throw Exception('MeaningCloud API error');
  }

  Future<String> _summarizeWithSmmry(String url, String text) async {
    // SMMRY API is free without API key for limited use

    log('hit _summarizeWithSmmry $text');

    try {
      final response = await _dio.post(
        'https://smmry.com/api/process-summarize',
        data: {'web_url': url},
        options: Options(
          headers: {'x-api-key': apiKey, 'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 500,
        ),
      );

      log(response.data.toString());

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['sm_api_content'] != null) {
          return data['sm_api_content'];
        }
      }
      throw Exception('SMMRY API error');
    } catch (e) {
      return _fallbackSummary(text);
    }
  }

  Future<String> _summarizeWithTextRazor(String text) async {
    if (apiKey == null) {
      throw Exception('TextRazor API key required');
    }

    final response = await _dio.post(
      'https://api.textrazor.com/',
      data: {'text': text, 'extractors': 'entities,topics'},
      options: Options(
        headers: {
          'x-textrazor-key': apiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
    );
    log(response.data.toString());
    if (response.statusCode == 200) {
      // Extract key sentences based on entities and topics
      final data = response.data;
      final sentences = (data['response']['sentences'] as List?)
          ?.take(3)
          .map((s) => s['text'])
          .join(' ');

      return sentences ?? _fallbackSummary(text);
    }

    throw Exception('TextRazor API error');
  }

  // ========================================================================
  // FALLBACK: Simple Extractive Summary (No API needed)
  // ========================================================================
  String _fallbackSummary(String text) {
    log('hit fall back summary');
    // Clean the text
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Split into sentences
    final sentences = cleanText
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty && s.trim().length > 20)
        .toList();

    if (sentences.isEmpty) {
      return 'Unable to generate summary from provided text.';
    }

    // Take first 3 sentences or all if less
    final summaryCount = sentences.length < 3 ? sentences.length : 3;
    final summary =
        '${sentences.take(summaryCount).map((s) => s.trim()).join('. ')}.';

    return summary;
  }

  Future<Map<String, dynamic>> analyzeContent(String text) async {
    // Mock content analysis
    await Future.delayed(Duration(seconds: 1));

    return {
      'language': 'en',
      'keywords': _extractKeywords(text),
      'sentiment': 'neutral',
    };
  }

  List<String> _extractKeywords(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final wordFreq = <String, int>{};

    for (var word in words) {
      if (word.length > 4) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }

    final sorted = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }
}
