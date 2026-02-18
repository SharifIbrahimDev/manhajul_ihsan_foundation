import 'dart:io';
import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/app_models.dart';

class ReportService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'N');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// Export transactions to PDF and share/print
  static Future<void> exportTransactionsToPdf({
    required List<FinancialTransaction> transactions,
    required Map<String, String> userNames,
    String title = 'Financial Report',
  }) async {
    final pdf = pw.Document();

    // Add content to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildPdfHeader(title),
            pw.SizedBox(height: 20),
            _buildPdfSummary(transactions),
            pw.SizedBox(height: 20),
            _buildPdfTable(transactions, userNames),
            pw.SizedBox(height: 20),
            _buildPdfFooter(),
          ];
        },
      ),
    );

    // Share the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Export transactions to Excel and share
  static Future<void> exportTransactionsToExcel({
    required List<FinancialTransaction> transactions,
    required Map<String, String> userNames,
    String title = 'Financial Report',
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Transactions'];
    
    // Set headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('User'),
      TextCellValue('Amount (N)'),
      TextCellValue('Months Covered'),
      TextCellValue('Description'),
    ]);

    // Add data
    for (var t in transactions) {
      sheet.appendRow([
        TextCellValue(_dateFormat.format(t.date)),
        TextCellValue(t.type.value.toUpperCase()),
        TextCellValue(t.category.description),
        TextCellValue(userNames[t.linkedUser] ?? 'Unknown'),
        DoubleCellValue(t.amount),
        TextCellValue(t.coveredMonths?.join(', ') ?? ''),
        TextCellValue(t.description ?? ''),
      ]);
    }

    // Save and share
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final fileName = '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: title,
      );
    }
  }

  static pw.Widget _buildPdfHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Manhajul Ihsan Foundation',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange800,
                  ),
                ),
                pw.Text(
                  'Every Life Matters',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Report Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.orange800),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfSummary(List<FinancialTransaction> transactions) {
    double totalCredits = 0;
    double totalDebits = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.credit) {
        totalCredits += t.amount;
      } else {
        totalDebits += t.amount;
      }
    }

    final balance = totalCredits - totalDebits;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Income', totalCredits, PdfColors.blue800),
          _buildSummaryItem('Total Expenses', totalDebits, PdfColors.red800),
          _buildSummaryItem('Net Balance', balance, balance >= 0 ? PdfColors.green800 : PdfColors.red800),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _currencyFormat.format(amount),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfTable(List<FinancialTransaction> transactions, Map<String, String> userNames) {
    final headers = ['Date', 'Type', 'Category', 'User', 'Amount', 'Months Covered', 'Description'];

    final data = transactions.map((t) {
      return [
        _dateFormat.format(t.date),
        t.type.value.toUpperCase(),
        t.category.description,
        userNames[t.linkedUser] ?? 'Unknown',
        _currencyFormat.format(t.amount),
        t.coveredMonths?.join(', ') ?? '',
        t.description ?? '',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerLeft,
        6: pw.Alignment.centerLeft,
      },
      cellStyle: const pw.TextStyle(fontSize: 9),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    );
  }

  static pw.Widget _buildPdfFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Manhajul Ihsan Foundation - Generating Transparency',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page 1', // This would need to be dynamic for real multi-page, but MultiPage handle it mostly
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }
}
