// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invoice _$InvoiceFromJson(Map<String, dynamic> json) => Invoice(
  invoiceNumber: json['invoiceNumber'] as String,
  saleRecord: SaleRecord.fromJson(json['saleRecord'] as Map<String, dynamic>),
  businessDetails: BusinessDetails.fromJson(
    json['businessDetails'] as Map<String, dynamic>,
  ),
  invoiceSettings: InvoiceSettings.fromJson(
    json['invoiceSettings'] as Map<String, dynamic>,
  ),
  generatedAt: DateTime.parse(json['generatedAt'] as String),
);

Map<String, dynamic> _$InvoiceToJson(Invoice instance) => <String, dynamic>{
  'invoiceNumber': instance.invoiceNumber,
  'saleRecord': instance.saleRecord,
  'businessDetails': instance.businessDetails,
  'invoiceSettings': instance.invoiceSettings,
  'generatedAt': instance.generatedAt.toIso8601String(),
};

BusinessDetails _$BusinessDetailsFromJson(Map<String, dynamic> json) =>
    BusinessDetails(
      address: json['address'] == null
          ? null
          : BusinessAddress.fromJson(json['address'] as Map<String, dynamic>),
      contact: json['contact'] == null
          ? null
          : BusinessContact.fromJson(json['contact'] as Map<String, dynamic>),
      tax: json['tax'] == null
          ? null
          : TaxInfo.fromJson(json['tax'] as Map<String, dynamic>),
      branding: json['branding'] == null
          ? null
          : BusinessBranding.fromJson(json['branding'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BusinessDetailsToJson(BusinessDetails instance) =>
    <String, dynamic>{
      'address': instance.address,
      'contact': instance.contact,
      'tax': instance.tax,
      'branding': instance.branding,
    };

BusinessAddress _$BusinessAddressFromJson(Map<String, dynamic> json) =>
    BusinessAddress(
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      country: json['country'] as String?,
    );

Map<String, dynamic> _$BusinessAddressToJson(BusinessAddress instance) =>
    <String, dynamic>{
      'street': instance.street,
      'city': instance.city,
      'state': instance.state,
      'zipCode': instance.zipCode,
      'country': instance.country,
    };

BusinessContact _$BusinessContactFromJson(Map<String, dynamic> json) =>
    BusinessContact(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
    );

Map<String, dynamic> _$BusinessContactToJson(BusinessContact instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'email': instance.email,
      'website': instance.website,
    };

TaxInfo _$TaxInfoFromJson(Map<String, dynamic> json) => TaxInfo(
  gstNumber: json['gstNumber'] as String?,
  panNumber: json['panNumber'] as String?,
  taxRegistered: json['taxRegistered'] as bool? ?? false,
);

Map<String, dynamic> _$TaxInfoToJson(TaxInfo instance) => <String, dynamic>{
  'gstNumber': instance.gstNumber,
  'panNumber': instance.panNumber,
  'taxRegistered': instance.taxRegistered,
};

BusinessBranding _$BusinessBrandingFromJson(Map<String, dynamic> json) =>
    BusinessBranding(
      logo: json['logo'] as String?,
      tagline: json['tagline'] as String?,
      primaryColor: json['primaryColor'] as String? ?? '#8D4E23',
    );

Map<String, dynamic> _$BusinessBrandingToJson(BusinessBranding instance) =>
    <String, dynamic>{
      'logo': instance.logo,
      'tagline': instance.tagline,
      'primaryColor': instance.primaryColor,
    };

InvoiceSettings _$InvoiceSettingsFromJson(Map<String, dynamic> json) =>
    InvoiceSettings(
      prefix: json['prefix'] as String? ?? 'INV',
      nextNumber: (json['nextNumber'] as num?)?.toInt() ?? 1,
      includeNotes: json['includeNotes'] as bool? ?? true,
      includeTax: json['includeTax'] as bool? ?? false,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$InvoiceSettingsToJson(InvoiceSettings instance) =>
    <String, dynamic>{
      'prefix': instance.prefix,
      'nextNumber': instance.nextNumber,
      'includeNotes': instance.includeNotes,
      'includeTax': instance.includeTax,
      'taxRate': instance.taxRate,
    };
