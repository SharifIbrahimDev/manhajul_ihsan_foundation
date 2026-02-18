import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/app_models.dart';
import '../users/edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/widgets/transaction_filter.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/toast_notification.dart';
import '../../core/widgets/sliver_delegate.dart';
import '../transactions/payment_details_screen.dart';
import '../transactions/monthly_contribution_screen.dart';
import '../../core/widgets/app_drawer.dart';


class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₦');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load user-specific transactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context
            .read<TransactionProvider>()
            .loadUserTransactions(authProvider.user!.uid);
      }
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
                _TransactionHistoryTab(),
                _ContributionSummaryTab(),
                _ProfileTab(),
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
                      'Welcome, ${user?.fullName ?? "User"}',
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
      child: Consumer2<TransactionProvider, AuthProvider>(
        builder: (context, transactionProvider, authProvider, child) {
          final userId = authProvider.user?.uid ?? '';
          final userContributions =
          transactionProvider.getUserTotalContributions(userId);
          final userTransactions = transactionProvider.transactions
              .where((t) => t.linkedUser == userId)
              .toList();
          final thisMonthTransactions = userTransactions.where((t) {
            final now = DateTime.now();
            return t.date.year == now.year && t.date.month == now.month;
          }).length;

          return Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  title: 'Total Contributions',
                  value: _currencyFormat.format(userContributions),
                  icon: Icons.volunteer_activism,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildOverviewCard(
                  title: 'Total Transactions',
                  value: userTransactions.length.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildOverviewCard(
                  title: 'This Month',
                  value: thisMonthTransactions.toString(),
                  icon: Icons.calendar_month,
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
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.black54,
        indicatorColor: AppTheme.primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Transactions', icon: Icon(Icons.history, size: 20)),
          Tab(text: 'Summary', icon: Icon(Icons.bar_chart, size: 20)),
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



class _TransactionHistoryTab extends StatefulWidget {
  const _TransactionHistoryTab();

  @override
  State<_TransactionHistoryTab> createState() => _TransactionHistoryTabState();
}

class _TransactionHistoryTabState extends State<_TransactionHistoryTab> {
  TransactionFilters _filters = TransactionFilters();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFilterSheet(
        currentFilters: _filters,
        onApply: (filters) {
          setState(() => _filters = filters);
          _searchController.text = filters.searchQuery ?? '';
          
          ToastNotification.showInfo(
            context, 
            'Filters applied successfully'
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, AuthProvider>(
      builder: (context, transactionProvider, authProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final userId = authProvider.user?.uid ?? '';
        final allUserTransactions = transactionProvider.transactions
            .where((t) => t.linkedUser == userId)
            .toList();
            
        // Apply filters
        _filters.searchQuery = _searchController.text;
        final filteredTransactions = filterTransactions(allUserTransactions, _filters);

        return Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      hintText: 'Search transactions...',
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _filters.searchQuery = value;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _filters.searchQuery = '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _filters.hasActiveFilters 
                          ? AppTheme.primaryColor 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: _filters.hasActiveFilters 
                            ? Colors.white 
                            : AppTheme.primaryColor,
                      ),
                      onPressed: _openFilterSheet,
                      tooltip: 'Filter Transactions',
                    ),
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              allUserTransactions.isEmpty 
                                  ? 'No Transactions Yet' 
                                  : 'No transactions found',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              allUserTransactions.isEmpty
                                  ? 'Your transaction history will appear here'
                                  : 'Try adjusting your search or filters',
                              style: const TextStyle(
                                color: Colors.black38,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (allUserTransactions.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _filters.clear();
                                    _searchController.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear Filters'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await transactionProvider.loadUserTransactions(userId);
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                           ToastNotification.showSuccess(
                            context, 
                            'Transactions refreshed'
                          );
                        }
                      },
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          return _buildTransactionItem(transaction);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(FinancialTransaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '₦');
    final isCredit = transaction.type == TransactionType.credit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          transaction.category.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.date),
              style: const TextStyle(fontSize: 12),
            ),
            if (transaction.description != null && transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transaction.description!,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}

class _ContributionSummaryTab extends StatelessWidget {
  const _ContributionSummaryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, AuthProvider>(
      builder: (context, transactionProvider, authProvider, child) {
        final userId = authProvider.user?.uid ?? '';
        final userTransactions = transactionProvider.transactions
            .where((t) => t.linkedUser == userId)
            .toList();

        final contributionsByCat = <TransactionCategory, double>{};
        for (var t in userTransactions) {
          if (t.type == TransactionType.credit) {
            contributionsByCat[t.category] = (contributionsByCat[t.category] ?? 0) + t.amount;
          }
        }

        final totalContributions = contributionsByCat.values.fold<double>(0, (sum, val) => sum + val);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.volunteer_activism, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Lifetime Contributions',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: '₦').format(totalContributions),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Breakdown by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (contributionsByCat.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No contributions recorded yet'),
                    ),
                  ),
                )
              else
                ...contributionsByCat.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.category, color: AppTheme.primaryColor, size: 20),
                      ),
                      title: Text(
                        entry.key.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(entry.key.description),
                      trailing: Text(
                        NumberFormat.currency(symbol: '₦').format(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.appUser;

        if (user == null) {
          return const Center(child: Text('No profile data available'));
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
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role.value,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
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
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.payments_rounded,
                      label: 'Make Payment',
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentDetailsScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.assignment_turned_in_rounded,
                      label: 'Contributions',
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MonthlyContributionScreen()),
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
