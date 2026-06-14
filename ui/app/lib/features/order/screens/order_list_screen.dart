import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/order/data/order_remote_data_source.dart';
import 'package:sync_app/features/order/state/active_order_count_notifier.dart';
import 'package:sync_app/features/order/models/order_models.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';
import 'package:sync_app/features/order/mock/order_demo_data.dart';
import 'package:sync_app/features/order/widgets/demo_order_card.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';
import 'package:sync_app/shared/widgets/sync_shimmer_box.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  final _api = getIt<OrderRemoteDataSource>();
  late final TabController _tabs;
  List<OrderSummary> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 1));
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _api.listOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
      await getIt<ActiveOrderCountNotifier>().refresh();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<OrderSummary> get _active => _orders.where((o) => o.isActive).toList();

  List<OrderSummary> get _history => _orders.where((o) => !o.isActive).toList();

  void _onOrderTap(OrderSummary order) {
    context.push(AppRoutes.orderDetail(order.id));
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
                  SyncShimmerBox(height: 96),
                  SizedBox(height: 12),
                  SyncShimmerBox(height: 96),
                ],
              )
            : TabBarView(
                controller: _tabs,
                children: [
                  _OrderList(items: _active, emptyText: 'Chưa có đơn đang giao', onTap: _onOrderTap),
                  _OrderList(items: _history, emptyText: 'Chưa có lịch sử đơn', onTap: _onOrderTap),
                ],
              ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.items,
    required this.emptyText,
    required this.onTap,
  });

  final List<OrderSummary> items;
  final String emptyText;
  final void Function(OrderSummary) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText, style: const TextStyle(color: OrderTheme.textMuted)));
    }

    return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final order = items[i];
          return DemoOrderCard(
            item: OrderListItemVm(order: order, partnerName: order.orderCode),
            onTap: () => onTap(order),
          );
        },
      );
  }
}
