// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BankAccountAdapter extends TypeAdapter<BankAccount> {
  @override
  final int typeId = 7;

  @override
  BankAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BankAccount(
      id: fields[0] as int,
      bankName: fields[1] as String,
      bankCode: fields[2] as String,
      accountNumber: fields[3] as String,
      maskedAccountNumber: fields[4] as String,
      accountName: fields[5] as String,
      accountType: fields[6] as String,
      bvn: fields[7] as String?,
      sortCode: fields[8] as String?,
      status: fields[9] as String,
      verificationStatus: fields[10] as String,
      isPrimary: fields[11] as bool,
      isActive: fields[12] as bool,
      verifiedAt: fields[13] as DateTime?,
      verificationAttempts: fields[14] as int,
      lastVerificationAttempt: fields[15] as DateTime?,
      verificationNotes: fields[16] as String?,
      totalPaymentsReceived: fields[17] as double,
      paymentCount: fields[18] as int,
      lastPaymentDate: fields[19] as DateTime?,
      displayName: fields[20] as String,
      verificationProgress: fields[21] as int,
      canReceivePayments: fields[22] as bool,
      createdAt: fields[23] as DateTime,
      updatedAt: fields[24] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BankAccount obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bankName)
      ..writeByte(2)
      ..write(obj.bankCode)
      ..writeByte(3)
      ..write(obj.accountNumber)
      ..writeByte(4)
      ..write(obj.maskedAccountNumber)
      ..writeByte(5)
      ..write(obj.accountName)
      ..writeByte(6)
      ..write(obj.accountType)
      ..writeByte(7)
      ..write(obj.bvn)
      ..writeByte(8)
      ..write(obj.sortCode)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.verificationStatus)
      ..writeByte(11)
      ..write(obj.isPrimary)
      ..writeByte(12)
      ..write(obj.isActive)
      ..writeByte(13)
      ..write(obj.verifiedAt)
      ..writeByte(14)
      ..write(obj.verificationAttempts)
      ..writeByte(15)
      ..write(obj.lastVerificationAttempt)
      ..writeByte(16)
      ..write(obj.verificationNotes)
      ..writeByte(17)
      ..write(obj.totalPaymentsReceived)
      ..writeByte(18)
      ..write(obj.paymentCount)
      ..writeByte(19)
      ..write(obj.lastPaymentDate)
      ..writeByte(20)
      ..write(obj.displayName)
      ..writeByte(21)
      ..write(obj.verificationProgress)
      ..writeByte(22)
      ..write(obj.canReceivePayments)
      ..writeByte(23)
      ..write(obj.createdAt)
      ..writeByte(24)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SupportedBankAdapter extends TypeAdapter<SupportedBank> {
  @override
  final int typeId = 8;

  @override
  SupportedBank read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SupportedBank(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[2] as String,
      shortName: fields[3] as String,
      isActive: fields[4] as bool,
      supportsInstantTransfer: fields[5] as bool,
      supportsBulkTransfer: fields[6] as bool,
      minTransferAmount: fields[7] as double,
      maxTransferAmount: fields[8] as double,
      transferFee: fields[9] as double,
      processingTimeMinutes: fields[10] as int,
      logoUrl: fields[11] as String?,
      nipBankCode: fields[12] as String?,
      bankId: fields[13] as String?,
      ussdTemplate: fields[14] as String?,
      baseUssdCode: fields[15] as String?,
      transferUssdTemplate: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SupportedBank obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.shortName)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.supportsInstantTransfer)
      ..writeByte(6)
      ..write(obj.supportsBulkTransfer)
      ..writeByte(7)
      ..write(obj.minTransferAmount)
      ..writeByte(8)
      ..write(obj.maxTransferAmount)
      ..writeByte(9)
      ..write(obj.transferFee)
      ..writeByte(10)
      ..write(obj.processingTimeMinutes)
      ..writeByte(11)
      ..write(obj.logoUrl)
      ..writeByte(12)
      ..write(obj.nipBankCode)
      ..writeByte(13)
      ..write(obj.bankId)
      ..writeByte(14)
      ..write(obj.ussdTemplate)
      ..writeByte(15)
      ..write(obj.baseUssdCode)
      ..writeByte(16)
      ..write(obj.transferUssdTemplate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportedBankAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BankAccount _$BankAccountFromJson(Map<String, dynamic> json) => BankAccount(
      id: (json['id'] as num).toInt(),
      bankName: json['bank_name'] as String,
      bankCode: json['bank_code'] as String,
      accountNumber: json['account_number'] as String,
      maskedAccountNumber: json['masked_account_number'] as String,
      accountName: json['account_name'] as String,
      accountType: json['account_type'] as String,
      bvn: json['bvn'] as String?,
      sortCode: json['sort_code'] as String?,
      status: json['status'] as String,
      verificationStatus: json['verification_status'] as String,
      isPrimary: json['is_primary'] as bool,
      isActive: json['is_active'] as bool,
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      verificationAttempts: (json['verification_attempts'] as num).toInt(),
      lastVerificationAttempt: json['last_verification_attempt'] == null
          ? null
          : DateTime.parse(json['last_verification_attempt'] as String),
      verificationNotes: json['verification_notes'] as String?,
      totalPaymentsReceived:
          (json['total_payments_received'] as num).toDouble(),
      paymentCount: (json['payment_count'] as num).toInt(),
      lastPaymentDate: json['last_payment_date'] == null
          ? null
          : DateTime.parse(json['last_payment_date'] as String),
      displayName: json['display_name'] as String,
      verificationProgress: (json['verification_progress'] as num).toInt(),
      canReceivePayments: json['can_receive_payments'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$BankAccountToJson(BankAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bank_name': instance.bankName,
      'bank_code': instance.bankCode,
      'account_number': instance.accountNumber,
      'masked_account_number': instance.maskedAccountNumber,
      'account_name': instance.accountName,
      'account_type': instance.accountType,
      'bvn': instance.bvn,
      'sort_code': instance.sortCode,
      'status': instance.status,
      'verification_status': instance.verificationStatus,
      'is_primary': instance.isPrimary,
      'is_active': instance.isActive,
      'verified_at': instance.verifiedAt?.toIso8601String(),
      'verification_attempts': instance.verificationAttempts,
      'last_verification_attempt':
          instance.lastVerificationAttempt?.toIso8601String(),
      'verification_notes': instance.verificationNotes,
      'total_payments_received': instance.totalPaymentsReceived,
      'payment_count': instance.paymentCount,
      'last_payment_date': instance.lastPaymentDate?.toIso8601String(),
      'display_name': instance.displayName,
      'verification_progress': instance.verificationProgress,
      'can_receive_payments': instance.canReceivePayments,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

SupportedBank _$SupportedBankFromJson(Map<String, dynamic> json) =>
    SupportedBank(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      shortName: json['short_name'] as String,
      isActive: json['is_active'] as bool,
      supportsInstantTransfer: json['supports_instant_transfer'] as bool,
      supportsBulkTransfer: json['supports_bulk_transfer'] as bool,
      minTransferAmount: _doubleFromString(json['min_transfer_amount']),
      maxTransferAmount: _doubleFromString(json['max_transfer_amount']),
      transferFee: _doubleFromString(json['transfer_fee']),
      processingTimeMinutes: (json['processing_time_minutes'] as num).toInt(),
      logoUrl: json['logo_url'] as String?,
      nipBankCode: json['nip_bank_code'] as String?,
      bankId: json['bank_id'] as String?,
      ussdTemplate: json['ussd_template'] as String?,
      baseUssdCode: json['base_ussd_code'] as String?,
      transferUssdTemplate: json['transfer_ussd_template'] as String?,
    );

Map<String, dynamic> _$SupportedBankToJson(SupportedBank instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'short_name': instance.shortName,
      'is_active': instance.isActive,
      'supports_instant_transfer': instance.supportsInstantTransfer,
      'supports_bulk_transfer': instance.supportsBulkTransfer,
      'min_transfer_amount': _doubleToString(instance.minTransferAmount),
      'max_transfer_amount': _doubleToString(instance.maxTransferAmount),
      'transfer_fee': _doubleToString(instance.transferFee),
      'processing_time_minutes': instance.processingTimeMinutes,
      'logo_url': instance.logoUrl,
      'nip_bank_code': instance.nipBankCode,
      'bank_id': instance.bankId,
      'ussd_template': instance.ussdTemplate,
      'base_ussd_code': instance.baseUssdCode,
      'transfer_ussd_template': instance.transferUssdTemplate,
    };

BankAccountStats _$BankAccountStatsFromJson(Map<String, dynamic> json) =>
    BankAccountStats(
      totalAccounts: (json['total_accounts'] as num).toInt(),
      verifiedAccounts: (json['verified_accounts'] as num).toInt(),
      pendingAccounts: (json['pending_accounts'] as num).toInt(),
      failedAccounts: (json['failed_accounts'] as num).toInt(),
      primaryAccount: json['primary_account'] == null
          ? null
          : BankAccount.fromJson(
              json['primary_account'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BankAccountStatsToJson(BankAccountStats instance) =>
    <String, dynamic>{
      'total_accounts': instance.totalAccounts,
      'verified_accounts': instance.verifiedAccounts,
      'pending_accounts': instance.pendingAccounts,
      'failed_accounts': instance.failedAccounts,
      'primary_account': instance.primaryAccount,
    };

BankValidationResult _$BankValidationResultFromJson(
        Map<String, dynamic> json) =>
    BankValidationResult(
      valid: json['valid'] as bool,
      bank: json['bank'] == null
          ? null
          : SupportedBank.fromJson(json['bank'] as Map<String, dynamic>),
      accountNumber: json['account_number'] as String,
      accountName: json['account_name'] as String?,
      message: json['message'] as String,
    );

Map<String, dynamic> _$BankValidationResultToJson(
        BankValidationResult instance) =>
    <String, dynamic>{
      'valid': instance.valid,
      'bank': instance.bank,
      'account_number': instance.accountNumber,
      'account_name': instance.accountName,
      'message': instance.message,
    };

BankVerificationLog _$BankVerificationLogFromJson(Map<String, dynamic> json) =>
    BankVerificationLog(
      id: (json['id'] as num).toInt(),
      bankAccountDisplay: json['bank_account_display'] as String,
      verificationType: json['verification_type'] as String,
      result: json['result'] as String,
      notes: json['notes'] as String?,
      errorMessage: json['error_message'] as String?,
      initiatedByUsername: json['initiated_by_username'] as String?,
      processedAt: DateTime.parse(json['processed_at'] as String),
      processingTime: json['processing_time'] as String?,
      externalReference: json['external_reference'] as String?,
    );

Map<String, dynamic> _$BankVerificationLogToJson(
        BankVerificationLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bank_account_display': instance.bankAccountDisplay,
      'verification_type': instance.verificationType,
      'result': instance.result,
      'notes': instance.notes,
      'error_message': instance.errorMessage,
      'initiated_by_username': instance.initiatedByUsername,
      'processed_at': instance.processedAt.toIso8601String(),
      'processing_time': instance.processingTime,
      'external_reference': instance.externalReference,
    };
