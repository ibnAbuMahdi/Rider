// Test file to check compilation
import 'lib/src/core/services/auth_service.dart';
import 'lib/src/core/models/rider.dart';

void main() {
  print('Testing compilation...');
  
  // Test AuthService methods
  final authService = AuthService();
  print('isPhoneNumber: ${authService.isPhoneNumber("08031234567")}');
  print('isPlateNumber: ${authService.isPlateNumber("ABC123DD")}');
  
  // Test Rider model with plateNumber
  final rider = Rider(
    id: 'test',
    phoneNumber: '+2348031234567',
    createdAt: DateTime.now(),
    plateNumber: 'ABC123DD',
  );
  
  print('Rider: ${rider.phoneNumber}, plate: ${rider.plateNumber}');
  print('Compilation test passed!');
}