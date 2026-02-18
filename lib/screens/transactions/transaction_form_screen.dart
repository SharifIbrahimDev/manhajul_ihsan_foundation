import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/utils/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/widgets/toast_notification.dart';

class TransactionFormScreen extends StatefulWidget {
  final FinancialTransaction? transaction; // If null, create new

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _selectedType;
  late TransactionCategory _selectedCategory;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedUserId;
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedMonths = []; // Format: "MM-YYYY"


  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize form with existing data or defaults
    if (widget.transaction != null) {
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _selectedUserId = widget.transaction!.linkedUser;
      _selectedDate = widget.transaction!.date;
      if (widget.transaction!.coveredMonths != null) {
        _selectedMonths.addAll(widget.transaction!.coveredMonths!);
      }
    } else {
      _selectedType = TransactionType.credit;
      _selectedCategory = TransactionCategory.monthly;
    }

    // Ensure users are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Transaction' : 'Record Transaction',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
              child: Column(
                children: [
                   Container(
                     padding: EdgeInsets.all(4.r),
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.2),
                       borderRadius: BorderRadius.circular(12.r),
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         _buildTypeButton(
                           TransactionType.credit, 
                           'Credit', 
                           Icons.arrow_downward
                         ),
                         _buildTypeButton(
                           TransactionType.debit, 
                           'Debit', 
                           Icons.arrow_upward
                         ),
                       ],
                     ),
                   ),
                   SizedBox(height: 24.h),
                   Text(
                     'Amount',
                     style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                   ),
                   SizedBox(height: 4.h),
                   FittedBox(
                     fit: BoxFit.scaleDown,
                     child: IntrinsicWidth(
                       child: TextField(
                         controller: _amountController,
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: 40.sp,
                           fontWeight: FontWeight.bold,
                         ),
                         textAlign: TextAlign.center,
                         decoration: InputDecoration(
                           border: InputBorder.none,
                           prefixText: '₦',
                           prefixStyle: TextStyle(
                             color: Colors.white70,
                             fontSize: 30.sp,
                           ),
                           hintText: '0.00',
                           hintStyle: TextStyle(
                             color: Colors.white30,
                             fontSize: 40.sp,
                           ),
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Details'),
                    
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDropdownField(
                            label: 'Category',
                            icon: Icons.category,
                            value: _selectedCategory,
                            items: TransactionCategory.values,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                          
                          if (_selectedCategory == TransactionCategory.monthly && _selectedType == TransactionType.credit) ...[
                            Divider(height: 32.h),
                            _buildMonthSelector(),
                          ],

                          
                          Divider(height: 32.h),
                          
                          GestureDetector(
                            onTap: () => _pickDate(context),
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: DateFormat('MMM dd, yyyy').format(_selectedDate),
                                ),
                                style: TextStyle(fontSize: 16.sp),
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  labelStyle: TextStyle(fontSize: 14.sp),
                                  prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 24.r),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          
                          Divider(height: 32.h),
                          
                          TextFormField(
                            controller: _descriptionController,
                            style: TextStyle(fontSize: 16.sp),
                            decoration: InputDecoration(
                              labelText: 'Description (Optional)',
                              labelStyle: TextStyle(fontSize: 14.sp),
                              prefixIcon: Icon(Icons.description, color: AppTheme.primaryColor, size: 24.r),
                              border: InputBorder.none,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    
                    if (_selectedType == TransactionType.credit) ...[
                      SizedBox(height: 24.h),
                      _buildSectionHeader('Linked User'),
                      
                      SizedBox(
                        height: 250.h, // Adjusted height
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            if (userProvider.isLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedUserId,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor, size: 24.r),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                ),
                                hint: Text(
                                  'Select User (Required)',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, size: 24.r),
                                items: userProvider.users.map((user) {
                                  return DropdownMenuItem<String>(
                                    value: user.uid,
                                    child: Text(
                                      user.fullName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedUserId = value);
                                },
                                validator: (value) {
                                  if (_selectedType == TransactionType.credit && value == null) {
                                    return 'Please select a user';
                                  }
                                  return null;
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    SizedBox(height: 32.h),

                    SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: _isProcessing
                            ? SizedBox(
                                width: 24.r,
                                height: 24.r,
                                child: const CircularProgressIndicator(color: Colors.white),
                              )
                            : Text(
                                isEditing ? 'Update Transaction' : 'Record Transaction',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18.r,
              color: isSelected ? AppTheme.primaryColor : Colors.white70,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required TransactionCategory value,
    required List<TransactionCategory> items,
    required Function(TransactionCategory?) onChanged,
  }) {
    return DropdownButtonFormField<TransactionCategory>(
      initialValue: value,
      style: TextStyle(
        fontSize: 16.sp,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 24.r),
        border: InputBorder.none,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item.value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor,
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ToastNotification.showError(context, 'Please enter a valid amount');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      
      final transaction = FinancialTransaction(
        id: widget.transaction?.id ?? '', // ID generated by Firestore for new
        type: _selectedType,
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
        description: _descriptionController.text.trim(),
        linkedUser: _selectedUserId ?? '',

        createdBy: authProvider.user!.uid,
        coveredMonths: (_selectedCategory == TransactionCategory.monthly && _selectedType == TransactionType.credit) 
            ? _selectedMonths 
            : null,
      );

      bool success;
      if (widget.transaction != null) {
        success = await transactionProvider.updateTransaction(transaction);
        if (success && context.mounted) {
           ToastNotification.showSuccess(context, 'Transaction updated successfully');
        }
      } else {
        success = await transactionProvider.createTransaction(transaction);
        if (success && context.mounted) {
           ToastNotification.showSuccess(context, 'Transaction recorded successfully');
           
           // Send notification to linked user if credit
           if (_selectedUserId != null && _selectedType == TransactionType.credit) {
             await notificationProvider.sendNotification(
               recipientId: _selectedUserId!,
               title: 'New Contribution Recorded',
               message: 'A contribution of ₦${NumberFormat('#,##0.00').format(amount)} has been recorded for you.',
               type: 'transaction',
             );
           }
        }
      }

      if (success && context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ToastNotification.showError(context, 'Error saving transaction: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }


  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Months',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () => _pickMonth(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: AppTheme.primaryColor, size: 24.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _selectedMonths.isEmpty
                        ? 'Select Months'
                        : _selectedMonths.map((m) {
                            final parts = m.split('-');
                            final date = DateTime(int.parse(parts[1]), int.parse(parts[0]));
                            return DateFormat('MMM yyyy').format(date);
                          }).join(', '),
                    style: TextStyle(fontSize: 14.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedMonths.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _selectedMonths.clear()),
                    child: Icon(Icons.close, size: 20.r, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2100);

    // Use built-in date picker but only care about month/year
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT MONTH (Day is ignored)',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      final monthKey = DateFormat('MM-yyyy').format(picked);
      setState(() {
        if (!_selectedMonths.contains(monthKey)) {
          _selectedMonths.add(monthKey);
          _selectedMonths.sort((a, b) {
            final aParts = a.split('-');
            final bParts = b.split('-');
            final aDate = DateTime(int.parse(aParts[1]), int.parse(aParts[0]));
            final bDate = DateTime(int.parse(bParts[1]), int.parse(bParts[0]));
            return aDate.compareTo(bDate);
          });
        }
      });
    }
  }
}
