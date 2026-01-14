import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore;

  PaymentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsCol =>
      _firestore.collection('payments');
  // Backend server URL - .env file se ya directly set karein
  String get _backendUrl {
    // Option 1: Environment variable se (preferred)
    final url = dotenv.env['PAYMENT_BACKEND_URL'];
    if (url != null && url.isNotEmpty) {
      return url.trim();
    }
    
    // Option 2: Default local development URL (for testing)
    // Note: Mobile app se localhost access nahi hoga, use ngrok or actual server
    if (kDebugMode) {
      // Development: Use ngrok URL or local network IP
      // Example: 'http://192.168.1.100:3000' (your local IP)
      // Or: 'https://your-ngrok-url.ngrok.io'
      return 'http://localhost:3000'; // ⚠️ Mobile app ke liye kaam nahi karega
    }
    
    // Option 3: Production URL - yahan apna backend URL set karein
    // TODO: Replace with your actual production backend URL
    throw Exception(
      'PAYMENT_BACKEND_URL not configured. Please set PAYMENT_BACKEND_URL in .env file or environment variables.'
    );
  }

  /// Create Stripe Checkout Session aur redirect karein
  Future<bool> createCheckoutAndRedirect({
    required double amount,
    required String bookingId,
    required String tutorId,
    required String parentId,
    String currency = 'inr', // Changed to INR for Indian Rupees
  }) async {
    try {
      // Check backend URL configuration
      String backendUrl;
      try {
        backendUrl = _backendUrl;
      } catch (e) {
        throw Exception(
          'Payment backend not configured. Please contact support.\n\nError: $e'
        );
      }

      // 1. Backend se Checkout Session create karein
      final sessionUrl = await createCheckoutSession(
        amount: amount,
        bookingId: bookingId,
        tutorId: tutorId,
        parentId: parentId,
        currency: currency,
      );

      if (sessionUrl == null || sessionUrl.isEmpty) {
        throw Exception(
          'Failed to create payment session. The payment server did not return a valid session URL. Please try again.'
        );
      }

      // 2. User ko Stripe payment page par redirect karein
      final uri = Uri.parse(sessionUrl);
      if (await canLaunchUrl(uri)) {
        // Use in-app webview for better UX (user app se bahar nahi jayega)
        await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView, // Changed from externalApplication to inAppWebView
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        return true;
      } else {
        throw Exception(
          'Unable to open payment page. Please ensure your device can open web pages.'
        );
      }
    } catch (e) {
      // Re-throw exceptions so they can be caught by ViewModel
      if (kDebugMode) {
        print('❌ Payment Service Error: $e');
      }
      rethrow;
    }
  }

  /// Backend se Stripe Checkout Session create karein
  Future<String?> createCheckoutSession({
    required double amount,
    required String bookingId,
    required String tutorId,
    required String parentId,
    String currency = 'inr', // Changed to INR for Indian Rupees
  }) async {
    try {
      final url = Uri.parse('$_backendUrl/api/create-checkout-session');
      
      if (kDebugMode) {
        print('📡 Payment Service: Backend URL: $url');
        print('📡 Payment Service: Request Data:');
        print('   Amount: $amount');
        print('   Booking ID: $bookingId');
        print('   Tutor ID: $tutorId');
        print('   Parent ID: $parentId');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'bookingId': bookingId,
          'tutorId': tutorId,
          'parentId': parentId,
          'currency': currency,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Payment request timeout. Please check your internet connection and try again.');
        },
      );

      if (kDebugMode) {
        print('📡 Payment Service: Response Status: ${response.statusCode}');
        print('📡 Payment Service: Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true && data['sessionUrl'] != null) {
            return data['sessionUrl'] as String;
          } else {
            final errorMsg = data['error'] ?? data['message'] ?? 'Invalid response from server';
            throw Exception('Failed to create payment session: $errorMsg');
          }
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Failed to parse server response. Please try again.');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Server error';
          throw Exception('Payment server error: $errorMessage');
        } catch (e) {
          if (e is Exception && !e.toString().contains('Payment server error')) {
            throw Exception('Server error (${response.statusCode}). Please try again later.');
          }
          rethrow;
        }
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ Payment Service SocketException: $e');
      }
      throw Exception('Unable to connect to payment server. Please check your internet connection and try again.');
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('❌ Payment Service ClientException: $e');
      }
      throw Exception('Network error. Please check your internet connection and try again.');
    } on Exception catch (e) {
      // Re-throw exceptions that are already properly formatted
      if (kDebugMode) {
        print('❌ Payment Service Exception: $e');
      }
      rethrow;
    } catch (e) {
      // Catch any other errors and wrap them
      if (kDebugMode) {
        print('❌ Payment Service Unknown Error: $e');
      }
      throw Exception('Payment failed: ${e.toString()}');
    }
  }

  // ---------- FIRESTORE OPERATIONS ----------

  /// Get all payments for a parent
  Future<List<PaymentModel>> getPaymentsByParentId(String parentId) async {
    try {
      final snapshot = await _paymentsCol
          .where('parentId', isEqualTo: parentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching payments: $e');
      }
      return [];
    }
  }

  /// Get payments by status for a parent
  Future<List<PaymentModel>> getPaymentsByParentAndStatus(
    String parentId,
    PaymentStatus status,
  ) async {
    try {
      final snapshot = await _paymentsCol
          .where('parentId', isEqualTo: parentId)
          .where('status', isEqualTo: PaymentModel.statusToString(status))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching payments by status: $e');
      }
      return [];
    }
  }

  /// Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _paymentsCol.doc(paymentId).get();
      if (!doc.exists) return null;
      return PaymentModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching payment: $e');
      }
      return null;
    }
  }

  /// Stream of payments for a parent (real-time updates)
  Stream<List<PaymentModel>> getPaymentsByParentIdStream(String parentId) {
    return _paymentsCol
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }
}
