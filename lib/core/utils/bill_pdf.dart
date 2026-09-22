import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/settings/domain/entities/shop_settings.dart';
import '../../features/vehicles/domain/entities/vehicle.dart';
import '../../features/visits/domain/entities/service_visit.dart';
import '../constants/app_info.dart';
import 'money_format.dart';
import 'shamsi_format.dart';

class BillPdf {
  BillPdf._();

  static pw.Font? _regular;
  static pw.Font? _medium;
  static pw.Font? _bold;

  static const _primary = PdfColor.fromInt(0xFF5B9FED);
  static const _primaryDark = PdfColor.fromInt(0xFF3B82D9);
  static const _ink = PdfColor.fromInt(0xFF1E293B);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _line = PdfColor.fromInt(0xFFE2E8F0);
  static const _surface = PdfColor.fromInt(0xFFF8FAFC);
  static const _white = PdfColors.white;

  static Future<void> _ensureFonts() async {
    if (_regular != null) return;
    final regular = await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    final medium = await rootBundle.load('assets/fonts/Vazirmatn-Medium.ttf');
    final bold = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    _regular = pw.Font.ttf(regular);
    _medium = pw.Font.ttf(medium);
    _bold = pw.Font.ttf(bold);
  }

  static pw.TextStyle _style({
    double size = 11,
    PdfColor color = _ink,
    pw.FontWeight weight = pw.FontWeight.normal,
  }) {
    final font = weight == pw.FontWeight.bold
        ? _bold!
        : weight == pw.FontWeight.normal
            ? _regular!
            : _medium!;
    return pw.TextStyle(font: font, fontSize: size, color: color);
  }

  static Future<Uint8List> build({
    required ServiceVisit visit,
    Vehicle? vehicle,
    ShopSettings? shop,
  }) async {
    await _ensureFonts();

    final shopName = (shop?.shopName.trim().isNotEmpty ?? false) ? shop!.shopName.trim() : AppInfo.nameFa;
    final invoiceNo = visit.id.toString();
    final dateText = ShamsiFormat.withTime(visit.happenedAt);
    final description = visit.note.trim().isNotEmpty ? visit.note.trim() : visit.title;

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _header(shopName: shopName, shop: shop),
              pw.SizedBox(height: 18),
              _metaRow(
                invoiceNo: invoiceNo,
                dateText: dateText,
              ),
              pw.SizedBox(height: 14),
              _customerCard(vehicle: vehicle, visit: visit),
              pw.SizedBox(height: 14),
              _workCard(title: visit.title, description: description),
              if (visit.partLines.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                _partsTable(visit.partLines),
              ],
              pw.SizedBox(height: 4),
              _totalsCard(visit: visit),
              pw.SizedBox(height: 16),
              _footer(shop: shop),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<void> preview({
    required ServiceVisit visit,
    Vehicle? vehicle,
    ShopSettings? shop,
  }) async {
    await Printing.layoutPdf(
      name: _fileName(visit),
      onLayout: (_) => build(visit: visit, vehicle: vehicle, shop: shop),
    );
  }

  static Future<void> share({
    required ServiceVisit visit,
    Vehicle? vehicle,
    ShopSettings? shop,
  }) async {
    final bytes = await build(visit: visit, vehicle: vehicle, shop: shop);
    await Printing.sharePdf(bytes: bytes, filename: _fileName(visit));
  }

  static String _fileName(ServiceVisit visit) => 'bill-${visit.id}-${ShamsiFormat.fileStamp(visit.happenedAt)}.pdf';

  static pw.Widget _header({
    required String shopName,
    ShopSettings? shop,
  }) {
    final phone = shop?.phone.trim() ?? '';
    final address = shop?.address.trim() ?? '';
    final owner = shop?.ownerName.trim() ?? '';

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(16),
        gradient: const pw.LinearGradient(
          begin: pw.Alignment.centerRight,
          end: pw.Alignment.centerLeft,
          colors: [_primaryDark, _primary],
        ),
      ),
      padding: const pw.EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shopName,
                  style: _style(size: 22, color: _white, weight: pw.FontWeight.bold),
                ),
                if (owner.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(owner, style: _style(size: 11, color: PdfColors.white),
                  ),
                ],
                if (phone.isNotEmpty || address.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  if (phone.isNotEmpty)
                    pw.Text('تماس: $phone', style: _style(size: 10, color: PdfColors.white)),
                  if (address.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(address, style: _style(size: 10, color: PdfColors.white)),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaRow({
    required String invoiceNo,
    required String dateText,
  }) {
    return pw.Row(
      children: [
        _infoChip(
          label: 'شماره',
          value: '#$invoiceNo',
        ),
        pw.SizedBox(width: 10),
        _infoChip(
          label: 'تاریخ',
          value: dateText,
        ),
      ],
    );
  }

  static pw.Widget _infoChip({
    required String label,
    required String value,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          color: _surface,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: _line),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: _style(size: 9, color: _muted)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: _style(size: 11, weight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _customerCard({
    Vehicle? vehicle,
    required ServiceVisit visit,
  }) {
    final rows = <pw.Widget>[];

    if (vehicle != null) {
      if (vehicle.ownerName.isNotEmpty) {
        rows.add(_detailLine('مشتری', vehicle.ownerName));
      }
      if (vehicle.ownerPhone.isNotEmpty) {
        rows.add(_detailLine('موبایل', vehicle.ownerPhone));
      }
      final carName = '${vehicle.make} ${vehicle.model}'.trim();
      rows.add(_detailLine('خودرو', carName.isNotEmpty ? carName : '—'));
      if (vehicle.vin.isNotEmpty) {
        rows.add(_detailLine('VIN', vehicle.vin));
      }
      if (vehicle.mileage > 0) {
        rows.add(_detailLine('کیلومتر', MoneyFormat.compact(vehicle.mileage)));
      }
    } else {
      rows.add(_detailLine('خودرو', 'نامشخص'));
    }

    return _sectionCard(
      title: 'اطلاعات مشتری',
      child: pw.Column(children: rows),
    );
  }

  static pw.Widget _workCard({
    required String title,
    required String description,
  }) {
    return _sectionCard(
      title: 'شرح کار',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: _style(size: 13, weight: pw.FontWeight.bold)),
          if (description != title) ...[
            pw.SizedBox(height: 8),
            pw.Text(description, style: _style(size: 11, color: _muted), textAlign: pw.TextAlign.justify),
          ],
        ],
      ),
    );
  }

  static pw.Widget _partsTable(List<VisitPartLine> lines) {
    return _sectionCard(
      title: 'قطعات',
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _line, width: 0.6),
          verticalInside: pw.BorderSide(color: _line, width: 0.6),
          top: pw.BorderSide(color: _line),
          bottom: pw.BorderSide(color: _line),
          left: pw.BorderSide(color: _line),
          right: pw.BorderSide(color: _line),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1.4),
          3: const pw.FlexColumnWidth(1.4),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _surface),
            children: [
              _tableCell('نام قطعه', bold: true),
              _tableCell('تعداد', bold: true, align: pw.TextAlign.center),
              _tableCell('فی', bold: true, align: pw.TextAlign.center),
              _tableCell('جمع', bold: true, align: pw.TextAlign.center),
            ],
          ),
          ...lines.map(
            (line) => pw.TableRow(
              children: [
                _tableCell(line.name),
                _tableCell(line.qty.toString(), align: pw.TextAlign.center),
                _tableCell(MoneyFormat.compact(line.unitPrice), align: pw.TextAlign.center),
                _tableCell(MoneyFormat.compact(line.total), align: pw.TextAlign.center, bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.right,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: _style(size: 10, weight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static pw.Widget _totalsCard({required ServiceVisit visit}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: _line),
      ),
      padding: const pw.EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: pw.Column(
        children: [
          if (visit.laborAmount > 0) _totalRow('اجرت', visit.laborAmount),
          if (visit.partsAmount > 0) ...[
            if (visit.laborAmount > 0) pw.SizedBox(height: 8),
            _totalRow('قطعه', visit.partsAmount),
          ],
          pw.SizedBox(height: 12),
          pw.Divider(color: _line, height: 1),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [_primaryDark, _primary],
              ),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('جمع کل', style: _style(size: 14, color: _white, weight: pw.FontWeight.bold)),
                pw.Text(
                  MoneyFormat.toman(visit.amount),
                  style: _style(size: 16, color: _white, weight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, int amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: _style(size: 11, color: _muted)),
        pw.Text(MoneyFormat.toman(amount), style: _style(size: 11, weight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _footer({ShopSettings? shop}) {
    return pw.Column(
      children: [
        pw.Divider(color: _line),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Text(
                'فاکتور رسمی محسوب نمیشود.',
                style: _style(size: 8, color: _muted),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              AppInfo.website,
              style: _style(size: 10, color: _primaryDark, weight: pw.FontWeight.bold),
              textDirection: pw.TextDirection.ltr,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionCard({
    required String title,
    required pw.Widget child,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _line),
      ),
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 16,
                decoration: pw.BoxDecoration(
                  color: _primary,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(title, style: _style(size: 12, weight: pw.FontWeight.bold, color: _primaryDark)),
            ],
          ),
          pw.SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  static pw.Widget _detailLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 64,
            child: pw.Text(label, style: _style(size: 10, color: _muted)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: _style(size: 11, weight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
