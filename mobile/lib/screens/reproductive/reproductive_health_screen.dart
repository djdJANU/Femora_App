import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'period_tab.dart';
import 'pregnancy_tab.dart';

/// Reproductive Health Screen
/// Manages Period and Pregnancy modules with tabbed navigation
class ReproductiveHealthScreen extends StatefulWidget {
  final int initialTab;

  const ReproductiveHealthScreen({super.key, this.initialTab = 0});

  @override
  State<ReproductiveHealthScreen> createState() =>
      _ReproductiveHealthScreenState();
}

class _ReproductiveHealthScreenState extends State<ReproductiveHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      appBar: AppBar(
        backgroundColor: FemoraColors.lightBackgroundTint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: FemoraColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reproductive Health',
          style: FemoraTextStyles.headlineMedium.copyWith(
            color: FemoraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: FemoraColors.primary,
            indicatorWeight: 3,
            labelColor: FemoraColors.primary,
            unselectedLabelColor: FemoraColors.textSecondary,
            dividerColor: Colors.transparent,
            labelStyle: FemoraTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: FemoraTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'Period'),
              Tab(text: 'Pregnancy'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [PeriodTab(), PregnancyTab()],
      ),
    );
  }
}
