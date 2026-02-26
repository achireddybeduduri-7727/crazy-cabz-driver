import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase Storage service for organizing files into separate folders
/// Each file type has its own folder for easy access and organization
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Storage folder paths
  static const String driverProfilePictures = 'profile_pictures/drivers';
  static const String riderProfilePictures = 'profile_pictures/riders';
  static const String rideDocuments = 'ride_documents';
  static const String companyFiles = 'company_files';
  static const String chatAttachments = 'chat_attachments';
  static const String supportAttachments = 'support_attachments';

  // ==================== PROFILE PICTURES ====================

  /// Upload driver profile picture
  Future<String?> uploadDriverProfilePicture({
    required String driverId,
    required dynamic file, // File for mobile, Uint8List for web
    String extension = 'jpg',
  }) async {
    try {
      final ref = _storage.ref('$driverProfilePictures/$driverId.$extension');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(Uint8List.fromList(file as List<int>));
      } else {
        uploadTask = ref.putFile(file as File);
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Driver profile picture uploaded: $driverId');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading driver profile picture: $e');
      return null;
    }
  }

  /// Upload rider profile picture
  Future<String?> uploadRiderProfilePicture({
    required String riderId,
    required dynamic file,
    String extension = 'jpg',
  }) async {
    try {
      final ref = _storage.ref('$riderProfilePictures/$riderId.$extension');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(Uint8List.fromList(file as List<int>));
      } else {
        uploadTask = ref.putFile(file as File);
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Rider profile picture uploaded: $riderId');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading rider profile picture: $e');
      return null;
    }
  }

  /// Get driver profile picture URL
  Future<String?> getDriverProfilePictureUrl(String driverId, {String extension = 'jpg'}) async {
    try {
      final ref = _storage.ref('$driverProfilePictures/$driverId.$extension');
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error getting driver profile picture: $e');
      return null;
    }
  }

  /// Get rider profile picture URL
  Future<String?> getRiderProfilePictureUrl(String riderId, {String extension = 'jpg'}) async {
    try {
      final ref = _storage.ref('$riderProfilePictures/$riderId.$extension');
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error getting rider profile picture: $e');
      return null;
    }
  }

  // ==================== RIDE DOCUMENTS ====================

  /// Upload ride document (receipt, invoice, etc.)
  Future<String?> uploadRideDocument({
    required String rideId,
    required dynamic file,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref('$rideDocuments/$rideId/$fileName');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(Uint8List.fromList(file as List<int>));
      } else {
        uploadTask = ref.putFile(file as File);
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Ride document uploaded: $rideId/$fileName');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading ride document: $e');
      return null;
    }
  }

  /// Get ride document URL
  Future<String?> getRideDocumentUrl(String rideId, String fileName) async {
    try {
      final ref = _storage.ref('$rideDocuments/$rideId/$fileName');
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error getting ride document: $e');
      return null;
    }
  }

  /// List all documents for a ride
  Future<List<String>> listRideDocuments(String rideId) async {
    try {
      final ref = _storage.ref('$rideDocuments/$rideId');
      final result = await ref.listAll();
      
      List<String> urls = [];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      print('❌ Error listing ride documents: $e');
      return [];
    }
  }

  // ==================== COMPANY FILES ====================

  /// Upload company file (terms, policies, etc.)
  Future<String?> uploadCompanyFile({
    required String fileName,
    required dynamic file,
  }) async {
    try {
      final ref = _storage.ref('$companyFiles/$fileName');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(Uint8List.fromList(file as List<int>));
      } else {
        uploadTask = ref.putFile(file as File);
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Company file uploaded: $fileName');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading company file: $e');
      return null;
    }
  }

  /// Get company file URL
  Future<String?> getCompanyFileUrl(String fileName) async {
    try {
      final ref = _storage.ref('$companyFiles/$fileName');
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error getting company file: $e');
      return null;
    }
  }

  /// List all company files
  Future<List<Map<String, String>>> listCompanyFiles() async {
    try {
      final ref = _storage.ref(companyFiles);
      final result = await ref.listAll();
      
      List<Map<String, String>> files = [];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        files.add({
          'name': item.name,
          'url': url,
        });
      }
      
      return files;
    } catch (e) {
      print('❌ Error listing company files: $e');
      return [];
    }
  }

  // ==================== CHAT ATTACHMENTS ====================

  /// Upload chat attachment
  Future<String?> uploadChatAttachment({
    required String chatId,
    required String messageId,
    required dynamic file,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref('$chatAttachments/$chatId/$messageId/$fileName');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(Uint8List.fromList(file as List<int>));
      } else {
        uploadTask = ref.putFile(file as File);
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Chat attachment uploaded: $chatId/$messageId/$fileName');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading chat attachment: $e');
      return null;
    }
  }

  /// Get chat attachment URL
  Future<String?> getChatAttachmentUrl(String chatId, String messageId, String fileName) async {
    try {
      final ref = _storage.ref('$chatAttachments/$chatId/$messageId/$fileName');
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error getting chat attachment: $e');
      return null;
    }
  }

  // ==================== SUPPORT ATTACHMENTS ====================

  /// Upload support ticket attachment
  Future<String?> uploadSupportAttachment({
    required String ticketId,
    required dynamic file,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref('$supportAttachments/$ticketId/$fileName');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(Uint8List.fromList(file as List<int>));
      } else {
        uploadTask = ref.putFile(file as File);
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Support attachment uploaded: $ticketId/$fileName');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading support attachment: $e');
      return null;
    }
  }

  /// Get support attachment URL
  Future<String?> getSupportAttachmentUrl(String ticketId, String fileName) async {
    try {
      final ref = _storage.ref('$supportAttachments/$ticketId/$fileName');
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error getting support attachment: $e');
      return null;
    }
  }

  /// List all attachments for a support ticket
  Future<List<Map<String, String>>> listSupportAttachments(String ticketId) async {
    try {
      final ref = _storage.ref('$supportAttachments/$ticketId');
      final result = await ref.listAll();
      
      List<Map<String, String>> files = [];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        files.add({
          'name': item.name,
          'url': url,
        });
      }
      
      return files;
    } catch (e) {
      print('❌ Error listing support attachments: $e');
      return [];
    }
  }

  // ==================== DELETE FILES ====================

  /// Delete a file from storage
  Future<bool> deleteFile(String filePath) async {
    try {
      final ref = _storage.ref(filePath);
      await ref.delete();
      print('✅ File deleted: $filePath');
      return true;
    } catch (e) {
      print('❌ Error deleting file: $e');
      return false;
    }
  }

  /// Delete driver profile picture
  Future<bool> deleteDriverProfilePicture(String driverId, {String extension = 'jpg'}) async {
    return await deleteFile('$driverProfilePictures/$driverId.$extension');
  }

  /// Delete rider profile picture
  Future<bool> deleteRiderProfilePicture(String riderId, {String extension = 'jpg'}) async {
    return await deleteFile('$riderProfilePictures/$riderId.$extension');
  }
}
