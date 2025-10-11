import 'package:json_annotation/json_annotation.dart';
import 'sale_record.dart';

part 'invoice.g.dart';

@JsonSerializable()
class Invoice {
  final String invoiceNumber;
  final SaleRecord saleRecord;
  final BusinessDetails businessDetails;
  final InvoiceSettings invoiceSettings;
  final DateTime generatedAt;

  const Invoice({
    required this.invoiceNumber,
    required this.saleRecord,
    required this.businessDetails,
    required this.invoiceSettings,
    required this.generatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

  // Helper methods
  double get totalAmount => saleRecord.totalAmount;
  double get taxAmount => invoiceSettings.includeTax
      ? (saleRecord.totalAmount * invoiceSettings.taxRate / 100)
      : 0.0;
  double get grandTotal => totalAmount + taxAmount;
}

@JsonSerializable()
class BusinessDetails {
  final BusinessAddress? address;
  final BusinessContact? contact;
  final TaxInfo? tax;
  final BusinessBranding? branding;

  const BusinessDetails({this.address, this.contact, this.tax, this.branding});

  factory BusinessDetails.fromJson(Map<String, dynamic> json) =>
      _$BusinessDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessDetailsToJson(this);
}

@JsonSerializable()
class BusinessAddress {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  const BusinessAddress({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  factory BusinessAddress.fromJson(Map<String, dynamic> json) =>
      _$BusinessAddressFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessAddressToJson(this);

  String get formattedAddress {
    final parts = <String>[];
    if (street?.isNotEmpty == true) parts.add(street!);
    if (city?.isNotEmpty == true) parts.add(city!);
    if (state?.isNotEmpty == true) parts.add(state!);
    if (zipCode?.isNotEmpty == true) parts.add(zipCode!);
    if (country?.isNotEmpty == true) parts.add(country!);
    return parts.join(', ');
  }
}

@JsonSerializable()
class BusinessContact {
  final String? phone;
  final String? email;
  final String? website;

  const BusinessContact({this.phone, this.email, this.website});

  factory BusinessContact.fromJson(Map<String, dynamic> json) =>
      _$BusinessContactFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessContactToJson(this);
}

@JsonSerializable()
class TaxInfo {
  final String? gstNumber;
  final String? panNumber;
  final bool taxRegistered;

  const TaxInfo({this.gstNumber, this.panNumber, this.taxRegistered = false});

  factory TaxInfo.fromJson(Map<String, dynamic> json) =>
      _$TaxInfoFromJson(json);

  Map<String, dynamic> toJson() => _$TaxInfoToJson(this);
}

@JsonSerializable()
class BusinessBranding {
  final String? logo;
  final String? tagline;
  final String primaryColor;

  const BusinessBranding({
    this.logo,
    this.tagline,
    this.primaryColor = '#8D4E23',
  });

  factory BusinessBranding.fromJson(Map<String, dynamic> json) =>
      _$BusinessBrandingFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessBrandingToJson(this);
}

@JsonSerializable()
class InvoiceSettings {
  final String prefix;
  final int nextNumber;
  final bool includeNotes;
  final bool includeTax;
  final double taxRate;

  const InvoiceSettings({
    this.prefix = 'INV',
    this.nextNumber = 1,
    this.includeNotes = true,
    this.includeTax = false,
    this.taxRate = 0.0,
  });

  factory InvoiceSettings.fromJson(Map<String, dynamic> json) =>
      _$InvoiceSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceSettingsToJson(this);
}
