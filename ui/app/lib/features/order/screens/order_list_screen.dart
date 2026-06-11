import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/order/config/mock_tracking_config.dart';
import 'package:sync_app/features/order/data/order_demo_repository.dart';
import 'package:sync_app/features/order/mock/order_demo_data.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';
import 'package:sync_app/features/order/widgets/demo_order_card.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';
import 'package:sync_app/shared/widgets/sync_shimmer_box.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  final _repo = getIt<OrderDemoRepository>();
  late final TabController _tabs;
  List<OrderListItemVm> _active = [];
  List<OrderListItemVm> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repo.loadOrders();
    if (mounted) {
      setState(() {
        _active = result.active;
        _history = result.history;
        _loading = false;
      });
    }
  }

  void _onOrderTap(OrderListItemVm item) {
    if (item.order.id == MockTrackingConfig.demoActiveOrderId && item.order.isActive) {
      context.push(AppRoutes.orderTracking(item.order.id));
      return;
    }
    context.push(AppRoutes.orderDetail(item.order.id));
  }

  @override
  Widget build(BuildContext context) {
    return AppShellOverlayScaffold(
      child: Scaffold(
        backgroundColor: OrderTheme.background,
        appBar: AppBar(
          backgroundColor: OrderTheme.background,
          elevation: 0,
          foregroundColor: OrderTheme.textPrimary,
          title: const Text('Đơn của tôi', style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: TabBar(
            controller: _tabs,
            labelColor: OrderTheme.accent,
            unselectedLabelColor: OrderTheme.textMuted,
            indicatorColor: OrderTheme.accent,
            tabs: const [
              Tab(text: 'Đang giao'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: _loading
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SyncShimmerBox(height: 100, borderRadius: 16),
                  SizedBox(height: 12),
                  SyncShimmerBox(height: 100, borderRadius: 16),
                ],
              )
            : TabBarView(
                controller: _tabs,
                children: [
                  _list(_active, emptyMessage: 'Chưa có đơn đang giao'),
                  _list(_history, emptyMessage: 'Chưa có đơn nào — đặt món từ Sync Foods nhé'),
                ],
              ),
      ),
    );
  }

  Widget _list(List<OrderListItemVm> orders, {required String emptyMessage}) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyMessage, textAlign: TextAlign.center, style: const TextStyle(color: OrderTheme.textMuted)),
        ),
      );
    }

    return RefreshIndicator(
      color: OrderTheme.accent,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: orders.length,
        itemBuilder: (_, i) => DemoOrderCard(
          item: orders[i],
          onTap: () => _onOrderTap(orders[i]),
        ),
      ),
    );
  }
}
