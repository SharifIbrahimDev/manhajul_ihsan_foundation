import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/utils/app_theme.dart';
import '../../core/widgets/financial_overview_widget.dart';
import '../../core/widgets/transaction_management_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/app_models.dart';
import '../../core/widgets/toast_notification.dart';
import '../../core/widgets/sliver_delegate.dart';
import '../users/edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/monthly_contribution_screen.dart';
import '../transactions/debtors_screen.dart';
import '../../core/widgets/app_drawer.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₦');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    // Load data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<UserProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildOverviewCards()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverAppBarDelegate(
                    _buildTabBar(),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: const [
                const FinancialOverviewWidget(),
                const TransactionManagementWidget(),
                const MonthlyContributionScreen(),
                const DebtorsScreen(),
                const _AddTransactionTab(),
                const _ProfileTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.r),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.appUser;
          return Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      color: AppTheme.primaryColor,
                      size: 24.r,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 50.r,
                height: 50.r,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: user?.photoUrl != null
                      ? Image.network(
                          user!.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Center(
                            child: Text(
                              'MIF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            'MIF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manhajul Ihsan Foundation',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Every Life Matters',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Welcome, ${user?.fullName ?? "Cashier"}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showLogoutDialog(),
                icon: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.logout, color: Colors.red, size: 20.r),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Container(
      height: 120.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final totalCredits = transactionProvider.getTotalCredits();
          final balance = transactionProvider.getTotalFunds();
          final recentTransactions =
          transactionProvider.getRecentTransactions(limit: 10);

          return Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  title: 'Total Balance',
                  value: _currencyFormat.format(balance),
                  icon: Icons.account_balance_wallet,
                  color: balance >= 0 ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildOverviewCard(
                  title: 'Total Income',
                  value: _currencyFormat.format(totalCredits),
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildOverviewCard(
                  title: 'Recent Transactions',
                  value: recentTransactions.length.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 24.r),
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.black54,
        indicatorColor: AppTheme.primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
          Tab(text: 'Transactions', icon: Icon(Icons.receipt_long, size: 20)),
          Tab(text: 'Monthly', icon: Icon(Icons.calendar_month, size: 20)),
          Tab(text: 'Debtors', icon: Icon(Icons.person_off, size: 20)),
          Tab(text: 'Add Transaction', icon: Icon(Icons.add_card, size: 20)),
          Tab(text: 'Profile', icon: Icon(Icons.person, size: 20)),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatProvider>().clearAllData();
              context.read<AuthProvider>().signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// -------------------------
/// Add Transaction Tab
/// -------------------------
class _AddTransactionTab extends StatefulWidget {
  const _AddTransactionTab();

  @override
  State<_AddTransactionTab> createState() => _AddTransactionTabState();
}

class _AddTransactionTabState extends State<_AddTransactionTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.credit;
  TransactionCategory _selectedCategory = TransactionCategory.monthly;
  AppUser? _selectedUser;
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedMonths = [];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add New Transaction',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Transaction Type
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<TransactionType>(
                      title: const Text('Credit (Income)'),
                      value: TransactionType.credit,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                          _selectedCategory = TransactionCategory.monthly;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<TransactionType>(
                      title: const Text('Debit (Expense)'),
                      value: TransactionType.debit,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                          _selectedCategory = TransactionCategory.marayu;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Category
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                items: _getAvailableCategories().map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.description),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedCategory = newValue!);
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₦)',
                  prefixIcon: Icon(Icons.money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Linked User
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return DropdownButtonFormField<AppUser>(
                    value: _selectedUser,
                    hint: const Text('Select User'),
                    items: userProvider.users.map((user) {
                      return DropdownMenuItem(
                        value: user,
                        child: Text('${user.fullName} (${user.email})'),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() => _selectedUser = newValue);
                    },
                    decoration: const InputDecoration(labelText: 'Linked User'),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_selectedCategory == TransactionCategory.monthly && _selectedType == TransactionType.credit) ...[
                _buildMonthSelector(),
                const SizedBox(height: 16),
              ],

              // Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down,
                          color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  return ElevatedButton(
                    onPressed: transactionProvider.isLoading
                        ? null
                        : _handleAddTransaction,
                    child: transactionProvider.isLoading
                        ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : const Text('Add Transaction'),
                  );
                },
              ),
              Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  if (transactionProvider.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        transactionProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TransactionCategory> _getAvailableCategories() {
    if (_selectedType == TransactionType.credit) {
      return [TransactionCategory.monthly, TransactionCategory.donation];
    } else {
      return [
        TransactionCategory.marayu,
        TransactionCategory.taimako,
        TransactionCategory.maralafiya,
      ];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleAddTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUser == null) {
      ToastNotification.showError(context, 'Please select a user');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    transactionProvider.clearError();

    final transaction = FinancialTransaction(
      id: '',
      type: _selectedType,
      category: _selectedCategory,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      linkedUser: _selectedUser!.uid,
      createdBy: authProvider.user!.uid,
      coveredMonths: (_selectedCategory == TransactionCategory.monthly && _selectedType == TransactionType.credit) 
          ? _selectedMonths 
          : null,
    );

    final success = await transactionProvider.createTransaction(transaction);

    if (success && mounted) {
      ToastNotification.showSuccess(context, 'Transaction added successfully!');
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedUser = null;
        _selectedDate = DateTime.now();
        _selectedType = TransactionType.credit;
        _selectedCategory = TransactionCategory.monthly;
        _selectedMonths.clear();
      });
    }
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Months Covered',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickMonth(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedMonths.isEmpty
                        ? 'Select Months'
                        : _selectedMonths.map((m) {
                            final parts = m.split('-');
                            final date = DateTime(int.parse(parts[1]), int.parse(parts[0]));
                            return DateFormat('MMM yyyy').format(date);
                          }).join(', '),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedMonths.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _selectedMonths.clear()),
                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

/// -------------------------
/// Profile Tab
/// -------------------------
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.appUser;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: user.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildInitialCircle(user),
                              ),
                            )
                          : _buildInitialCircle(user),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role.value,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.edit_note_rounded,
                      label: 'Edit Profile',
                      color: AppTheme.primaryColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditProfileScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.settings_suggest_rounded,
                      label: 'Settings',
                      color: Colors.blueGrey,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SettingsScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Information Section
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoTile(Icons.phone_iphone_rounded, 'Phone Number', user.phone),
              const SizedBox(height: 12),
              _buildInfoTile(Icons.home_work_rounded, 'Address', user.address),
              const SizedBox(height: 12),
              _buildInfoTile(
                Icons.calendar_today_rounded, 
                'Member Since', 
                DateFormat('MMMM dd, yyyy').format(user.createdAt)
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialCircle(AppUser user) {
    return Center(
      child: Text(
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
