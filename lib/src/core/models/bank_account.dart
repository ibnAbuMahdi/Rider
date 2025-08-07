import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bank_account.g.dart';

@HiveType(typeId: 7)
@JsonSerializable()
class BankAccount {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  @JsonKey(name: 'bank_name')
  final String bankName;
  
  @HiveField(2)
  @JsonKey(name: 'bank_code')
  final String bankCode;
  
  @HiveField(3)
  @JsonKey(name: 'account_number')
  final String accountNumber;
  
  @HiveField(4)
  @JsonKey(name: 'masked_account_number')
  final String maskedAccountNumber;
  
  @HiveField(5)
  @JsonKey(name: 'account_name')
  final String accountName;
  
  @HiveField(6)
  @JsonKey(name: 'account_type')
  final String accountType;
  
  @HiveField(7)
  final String? bvn;
  
  @HiveField(8)
  @JsonKey(name: 'sort_code')
  final String? sortCode;
  
  @HiveField(9)
  final String status;
  
  @HiveField(10)
  @JsonKey(name: 'verification_status')
  final String verificationStatus;
  
  @HiveField(11)
  @JsonKey(name: 'is_primary')
  final bool isPrimary;
  
  @HiveField(12)
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @HiveField(13)
  @JsonKey(name: 'verified_at')
  final DateTime? verifiedAt;
  
  @HiveField(14)
  @JsonKey(name: 'verification_attempts')
  final int verificationAttempts;
  
  @HiveField(15)
  @JsonKey(name: 'last_verification_attempt')
  final DateTime? lastVerificationAttempt;
  
  @HiveField(16)
  @JsonKey(name: 'verification_notes')
  final String? verificationNotes;
  
  @HiveField(17)
  @JsonKey(name: 'total_payments_received')
  final double totalPaymentsReceived;
  
  @HiveField(18)
  @JsonKey(name: 'payment_count')
  final int paymentCount;
  
  @HiveField(19)
  @JsonKey(name: 'last_payment_date')
  final DateTime? lastPaymentDate;
  
  @HiveField(20)
  @JsonKey(name: 'display_name')
  final String displayName;
  
  @HiveField(21)
  @JsonKey(name: 'verification_progress')
  final int verificationProgress;
  
  @HiveField(22)
  @JsonKey(name: 'can_receive_payments')
  final bool canReceivePayments;
  
  @HiveField(23)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @HiveField(24)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const BankAccount({
    required this.id,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.maskedAccountNumber,
    required this.accountName,
    required this.accountType,
    this.bvn,
    this.sortCode,
    required this.status,
    required this.verificationStatus,
    required this.isPrimary,
    required this.isActive,
    this.verifiedAt,
    required this.verificationAttempts,
    this.lastVerificationAttempt,
    this.verificationNotes,
    required this.totalPaymentsReceived,
    required this.paymentCount,
    this.lastPaymentDate,
    required this.displayName,
    required this.verificationProgress,
    required this.canReceivePayments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) => _$BankAccountFromJson(json);
  Map<String, dynamic> toJson() => _$BankAccountToJson(this);

  // Getters for UI display
  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isFailed => verificationStatus == 'failed';
  bool get isUnverified => verificationStatus == 'unverified';
  
  bool get canRetryVerification => verificationAttempts < 5 && !isVerified;
  
  String get statusDisplay {
    switch (verificationStatus) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending Verification';
      case 'failed':
        return 'Verification Failed';
      case 'unverified':
        return 'Not Verified';
      default:
        return 'Unknown';
    }
  }
  
  String get accountTypeDisplay {
    switch (accountType) {
      case 'savings':
        return 'Savings Account';
      case 'current':
        return 'Current Account';
      case 'domiciliary':
        return 'Domiciliary Account';
      default:
        return accountType;
    }
  }
}

@HiveType(typeId: 8)
@JsonSerializable()
class SupportedBank {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String code;
  
  @HiveField(3)
  @JsonKey(name: 'short_name')
  final String shortName;
  
  @HiveField(4)
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @HiveField(5)
  @JsonKey(name: 'supports_instant_transfer')
  final bool supportsInstantTransfer;
  
  @HiveField(6)
  @JsonKey(name: 'supports_bulk_transfer')
  final bool supportsBulkTransfer;
  
  @HiveField(7)
  @JsonKey(name: 'min_transfer_amount')
  final double minTransferAmount;
  
  @HiveField(8)
  @JsonKey(name: 'max_transfer_amount')
  final double maxTransferAmount;
  
  @HiveField(9)
  @JsonKey(name: 'transfer_fee')
  final double transferFee;
  
  @HiveField(10)
  @JsonKey(name: 'processing_time_minutes')
  final int processingTimeMinutes;
  
  @HiveField(11)
  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  const SupportedBank({
    required this.id,
    required this.name,
    required this.code,
    required this.shortName,
    required this.isActive,
    required this.supportsInstantTransfer,
    required this.supportsBulkTransfer,
    required this.minTransferAmount,
    required this.maxTransferAmount,
    required this.transferFee,
    required this.processingTimeMinutes,
    this.logoUrl,
  });

  factory SupportedBank.fromJson(Map<String, dynamic> json) => _$SupportedBankFromJson(json);
  Map<String, dynamic> toJson() => _$SupportedBankToJson(this);
  
  String get processingTimeDisplay {
    if (processingTimeMinutes == 0) {
      return 'Instant';
    } else if (processingTimeMinutes < 60) {
      return '${processingTimeMinutes}m';
    } else {
      final hours = processingTimeMinutes ~/ 60;
      final minutes = processingTimeMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }
}

@JsonSerializable()
class BankAccountStats {
  @JsonKey(name: 'total_accounts')
  final int totalAccounts;
  
  @JsonKey(name: 'verified_accounts')
  final int verifiedAccounts;
  
  @JsonKey(name: 'pending_accounts')
  final int pendingAccounts;
  
  @JsonKey(name: 'failed_accounts')
  final int failedAccounts;
  
  @JsonKey(name: 'primary_account')
  final BankAccount? primaryAccount;

  const BankAccountStats({
    required this.totalAccounts,
    required this.verifiedAccounts,
    required this.pendingAccounts,
    required this.failedAccounts,
    this.primaryAccount,
  });

  factory BankAccountStats.fromJson(Map<String, dynamic> json) => _$BankAccountStatsFromJson(json);
  Map<String, dynamic> toJson() => _$BankAccountStatsToJson(this);
  
  bool get hasAccounts => totalAccounts > 0;
  bool get hasPrimaryAccount => primaryAccount != null;
  double get verificationRate => totalAccounts > 0 ? verifiedAccounts / totalAccounts : 0.0;
}

@JsonSerializable()
class BankValidationResult {
  final bool valid;
  final SupportedBank? bank;
  @JsonKey(name: 'account_number')
  final String accountNumber;
  @JsonKey(name: 'account_name')
  final String? accountName;
  final String message;

  const BankValidationResult({
    required this.valid,
    this.bank,
    required this.accountNumber,
    this.accountName,
    required this.message,
  });

  factory BankValidationResult.fromJson(Map<String, dynamic> json) => _$BankValidationResultFromJson(json);
  Map<String, dynamic> toJson() => _$BankValidationResultToJson(this);
}

@JsonSerializable()
class BankVerificationLog {
  final int id;
  @JsonKey(name: 'bank_account_display')
  final String bankAccountDisplay;
  @JsonKey(name: 'verification_type')
  final String verificationType;
  final String result;
  final String? notes;
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  @JsonKey(name: 'initiated_by_username')
  final String? initiatedByUsername;
  @JsonKey(name: 'processed_at')
  final DateTime processedAt;
  @JsonKey(name: 'processing_time')
  final String? processingTime;
  @JsonKey(name: 'external_reference')
  final String? externalReference;

  const BankVerificationLog({
    required this.id,
    required this.bankAccountDisplay,
    required this.verificationType,
    required this.result,
    this.notes,
    this.errorMessage,
    this.initiatedByUsername,
    required this.processedAt,
    this.processingTime,
    this.externalReference,
  });

  factory BankVerificationLog.fromJson(Map<String, dynamic> json) => _$BankVerificationLogFromJson(json);
  Map<String, dynamic> toJson() => _$BankVerificationLogToJson(this);
  
  bool get isSuccess => result == 'success';
  bool get isFailed => result == 'failed';
  bool get isPending => result == 'pending';
  
  String get resultDisplay {
    switch (result) {
      case 'success':
        return 'Successful';
      case 'failed':
        return 'Failed';
      case 'pending':
        return 'Pending';
      case 'error':
        return 'Error';
      default:
        return result;
    }
  }
}