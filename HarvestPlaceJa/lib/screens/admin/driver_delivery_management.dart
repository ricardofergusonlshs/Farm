part of harvest_place_app;

// ============================================================================
// DRIVER & DELIVERY MANAGEMENT — PHASE 1
//
// This file is intentionally self-contained so it can be added as one new
// `part` file without replacing admin_screens.dart.
// ============================================================================

List<Map<String, dynamic>> _driverManagementRows(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];

  return value
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList(growable: false);
}

class DriverStaffOption {
  final String userId;
  final String email;
  final String fullName;

  const DriverStaffOption({
    required this.userId,
    required this.email,
    required this.fullName,
  });

  factory DriverStaffOption.fromMap(Map<String, dynamic> data) {
    return DriverStaffOption(
      userId: (data['user_id'] ?? '').toString().trim(),
      email: (data['email'] ?? '').toString().trim().toLowerCase(),
      fullName: (data['full_name'] ?? '').toString().trim(),
    );
  }

  String get displayName => fullName.isNotEmpty ? fullName : email;
}

class DriverDeliveryItem {
  final String productName;
  final int quantity;
  final double lineTotal;

  const DriverDeliveryItem({
    required this.productName,
    required this.quantity,
    required this.lineTotal,
  });

  factory DriverDeliveryItem.fromMap(Map<String, dynamic> data) {
    return DriverDeliveryItem(
      productName: (data['product_name'] ?? 'Product').toString().trim(),
      quantity: Product._toInt(data['quantity']),
      lineTotal: Product._toDouble(data['line_total']),
    );
  }
}

class DriverDeliveryTask {
  final String? assignmentId;
  final String orderId;
  final String orderStatus;
  final String deliveryStatus;
  final String assignmentStatus;
  final String? driverUserId;
  final String driverEmail;
  final String driverName;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String deliveryZone;
  final String? scheduledDate;
  final String? scheduledTime;
  final double total;
  final String paymentStatus;
  final String paymentMethod;
  final String? managerNotes;
  final String? driverNotes;
  final String? failureReason;
  final DateTime? rescheduledFor;
  final String? proofPhotoPath;
  final String? recipientName;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? failedAt;
  final DateTime? createdAt;
  final List<DriverDeliveryItem> items;

  const DriverDeliveryTask({
    this.assignmentId,
    required this.orderId,
    required this.orderStatus,
    required this.deliveryStatus,
    required this.assignmentStatus,
    this.driverUserId,
    required this.driverEmail,
    required this.driverName,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.deliveryZone,
    this.scheduledDate,
    this.scheduledTime,
    required this.total,
    required this.paymentStatus,
    required this.paymentMethod,
    this.managerNotes,
    this.driverNotes,
    this.failureReason,
    this.rescheduledFor,
    this.proofPhotoPath,
    this.recipientName,
    this.assignedAt,
    this.acceptedAt,
    this.outForDeliveryAt,
    this.deliveredAt,
    this.failedAt,
    this.createdAt,
    required this.items,
  });

  factory DriverDeliveryTask.fromMap(Map<String, dynamic> data) {
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => DriverDeliveryItem.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <DriverDeliveryItem>[];

    return DriverDeliveryTask(
      assignmentId: data['assignment_id']?.toString(),
      orderId: (data['order_id'] ?? '').toString().trim(),
      orderStatus: (data['order_status'] ?? 'pending').toString().trim(),
      deliveryStatus: (data['delivery_status'] ?? 'pending').toString().trim(),
      assignmentStatus:
          (data['assignment_status'] ?? 'unassigned').toString().trim(),
      driverUserId: data['driver_user_id']?.toString(),
      driverEmail: (data['driver_email'] ?? '').toString().trim(),
      driverName: (data['driver_name'] ?? '').toString().trim(),
      customerName: (data['customer_name'] ?? 'Customer').toString().trim(),
      customerPhone: (data['customer_phone'] ?? '').toString().trim(),
      deliveryAddress: (data['delivery_address'] ?? '').toString().trim(),
      deliveryZone: (data['delivery_zone'] ?? '').toString().trim(),
      scheduledDate: data['scheduled_date']?.toString(),
      scheduledTime: data['scheduled_time']?.toString(),
      total: Product._toDouble(data['total']),
      paymentStatus: (data['payment_status'] ?? 'unpaid').toString().trim(),
      paymentMethod: (data['payment_method'] ?? '').toString().trim(),
      managerNotes: data['manager_notes']?.toString(),
      driverNotes: data['driver_notes']?.toString(),
      failureReason: data['failure_reason']?.toString(),
      rescheduledFor: parseProductDate(data['rescheduled_for']),
      proofPhotoPath: data['proof_photo_path']?.toString(),
      recipientName: data['recipient_name']?.toString(),
      assignedAt: parseProductDate(data['assigned_at']),
      acceptedAt: parseProductDate(data['accepted_at']),
      outForDeliveryAt: parseProductDate(data['out_for_delivery_at']),
      deliveredAt: parseProductDate(data['delivered_at']),
      failedAt: parseProductDate(data['failed_at']),
      createdAt: parseProductDate(data['created_at']),
      items: items,
    );
  }

  String get shortId => shortIdLabel(orderId);

  String get statusKey {
    final clean = assignmentStatus.trim().toLowerCase();
    return clean.isEmpty ? 'unassigned' : clean;
  }

  String get statusLabel => friendlyLabel(statusKey);

  String get formattedTotal => formatJmd(total);

  String get formattedPayment => formatPaymentStatusForMethod(
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
      );

  String get scheduleText => formatScheduleText(scheduledDate, scheduledTime);

  bool get isCompleted => statusKey == 'delivered';
  bool get canAccept => statusKey == 'assigned';
  bool get canStart =>
      statusKey == 'assigned' ||
      statusKey == 'accepted' ||
      statusKey == 'failed' ||
      statusKey == 'rescheduled';
  bool get canComplete => statusKey == 'out_for_delivery';
  bool get canReportProblem =>
      statusKey == 'accepted' || statusKey == 'out_for_delivery';
}

class _DriverManagementData {
  final String role;
  final List<DriverStaffOption> drivers;
  final List<DriverDeliveryTask> unassigned;
  final List<DriverDeliveryTask> tasks;

  const _DriverManagementData({
    required this.role,
    required this.drivers,
    required this.unassigned,
    required this.tasks,
  });

  bool get managerView => role == 'owner' || role == 'manager';
}

Future<List<DriverStaffOption>> fetchDeliveryDriverOptions() async {
  final response = await supabase.rpc('hp_list_delivery_staff');
  return _driverManagementRows(response)
      .map(DriverStaffOption.fromMap)
      .where((driver) => driver.userId.isNotEmpty)
      .toList(growable: false);
}

Future<List<DriverDeliveryTask>> fetchUnassignedDriverOrders() async {
  final response = await supabase.rpc('hp_unassigned_delivery_orders');
  return _driverManagementRows(response)
      .map(DriverDeliveryTask.fromMap)
      .where((task) => task.orderId.isNotEmpty)
      .toList(growable: false);
}

Future<List<DriverDeliveryTask>> fetchDriverDeliveryTasks({
  required bool managerView,
}) async {
  final functionName =
      managerView ? 'hp_delivery_tasks_for_admin' : 'hp_my_delivery_tasks';
  final response = await supabase.rpc(functionName);
  return _driverManagementRows(response)
      .map(DriverDeliveryTask.fromMap)
      .where((task) => task.orderId.isNotEmpty)
      .toList(growable: false);
}

Future<void> assignDriverToDelivery({
  required String orderId,
  required String driverUserId,
  String? managerNotes,
}) async {
  await supabase.rpc(
    'hp_assign_delivery',
    params: <String, dynamic>{
      'p_order_id': orderId,
      'p_driver_user_id': driverUserId,
      'p_manager_notes': managerNotes,
    },
  );

  try {
    await createOrderCustomerNotification(
      orderId: orderId,
      title: 'Delivery assigned',
      message:
          'A driver has been assigned to order #${shortIdLabel(orderId)}. You will receive another update when it leaves for delivery.',
      type: 'delivery',
    );
  } catch (error) {
    // The assignment RPC above is the business commit boundary. A temporary
    // notification failure must not make a successful assignment look failed
    // or encourage the manager to submit it a second time.
    farmDebugLog(
      'Delivery assignment notification deferred for $orderId: $error',
    );
  }
}

Future<void> unassignDriverDelivery({
  required String orderId,
  String? reason,
}) async {
  await supabase.rpc(
    'hp_unassign_delivery',
    params: <String, dynamic>{
      'p_order_id': orderId,
      'p_reason': reason,
    },
  );
}

String _driverStatusCustomerMessage(
  DriverDeliveryTask task,
  String status, {
  DateTime? rescheduledFor,
  String? recipientName,
}) {
  final shortId = task.shortId;

  switch (status) {
    case 'accepted':
      return 'Your driver accepted order #$shortId and is preparing for delivery.';
    case 'out_for_delivery':
      return 'Order #$shortId is now out for delivery.';
    case 'delivered':
      final recipient = (recipientName ?? '').trim();
      return recipient.isEmpty
          ? 'Order #$shortId was marked delivered.'
          : 'Order #$shortId was delivered to $recipient.';
    case 'failed':
      return 'The delivery attempt for order #$shortId was unsuccessful. The team will contact you.';
    case 'rescheduled':
      return rescheduledFor == null
          ? 'The delivery for order #$shortId has been rescheduled.'
          : 'The delivery for order #$shortId has been rescheduled for ${formatCustomerDateTime(rescheduledFor)}.';
    default:
      return 'Order #$shortId delivery status is ${friendlyLabel(status)}.';
  }
}

Future<void> updateDriverDeliveryTask({
  required DriverDeliveryTask task,
  required String status,
  String? driverNotes,
  String? failureReason,
  DateTime? rescheduledFor,
  String? proofPhotoPath,
  String? recipientName,
}) async {
  await supabase.rpc(
    'hp_update_delivery_task',
    params: <String, dynamic>{
      'p_order_id': task.orderId,
      'p_status': status,
      'p_driver_notes': driverNotes,
      'p_failure_reason': failureReason,
      'p_rescheduled_for': rescheduledFor?.toIso8601String(),
      'p_proof_photo_path': proofPhotoPath,
      'p_recipient_name': recipientName,
    },
  );

  try {
    await createOrderCustomerNotification(
      orderId: task.orderId,
      title: 'Delivery update',
      message: _driverStatusCustomerMessage(
        task,
        status,
        rescheduledFor: rescheduledFor,
        recipientName: recipientName,
      ),
      type: 'delivery',
    );
  } catch (error) {
    // hp_update_delivery_task is the business commit boundary. Keep delivery
    // status truthful even if the secondary notification channel is unavailable.
    farmDebugLog(
      'Delivery customer notification deferred for ${task.orderId}: $error',
    );
  }

  if (status == 'failed') {
    try {
      await createAdminNotification(
        title: 'Delivery attempt failed',
        message:
            'Order #${task.shortId} could not be delivered. ${failureReason ?? ''}',
        type: 'delivery',
        orderId: task.orderId,
      );
    } catch (error) {
      farmDebugLog(
        'Failed-delivery admin notification deferred for ${task.orderId}: $error',
      );
    }
  }
}

Future<String> uploadDeliveryProofPhoto({
  required String orderId,
  required PickedProductImage image,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('Please sign in again before uploading proof.');
  }

  final bytes = image.bytes;
  if (bytes.isEmpty) {
    throw Exception('The selected proof photo is empty.');
  }

  const maxBytes = 6 * 1024 * 1024;
  if (bytes.length > maxBytes) {
    throw Exception('Use a delivery proof image smaller than 6 MB.');
  }

  final cleanOrderId = orderId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  final mime = image.mimeType.trim().toLowerCase();
  final lowerName = image.fileName.toLowerCase();
  final extension = mime == 'image/png' || lowerName.endsWith('.png')
      ? 'png'
      : mime == 'image/webp' || lowerName.endsWith('.webp')
          ? 'webp'
          : 'jpg';
  final contentType = extension == 'png'
      ? 'image/png'
      : extension == 'webp'
          ? 'image/webp'
          : 'image/jpeg';
  final path =
      '${user.id}/$cleanOrderId/${DateTime.now().millisecondsSinceEpoch}.$extension';

  await supabase.storage.from('delivery-proof').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

  return path;
}

Future<String?> createDeliveryProofSignedUrl(String? path) async {
  final clean = (path ?? '').trim();
  if (clean.isEmpty) return null;

  try {
    return await supabase.storage
        .from('delivery-proof')
        .createSignedUrl(clean, 3600);
  } catch (error) {
    farmDebugLog('Delivery proof signed URL unavailable: $error');
    return null;
  }
}

Future<void> deleteDeliveryProofPhoto(String? path) async {
  final clean = (path ?? '').trim();
  if (clean.isEmpty) return;

  try {
    await supabase.storage.from('delivery-proof').remove(<String>[clean]);
  } catch (error) {
    // Cleanup is best effort. Never hide the original delivery error because a
    // temporary Storage problem prevented deletion of an unused proof image.
    farmDebugLog('Unused delivery proof cleanup deferred for $clean: $error');
  }
}

class AdminDriverManagementTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminDriverManagementTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminDriverManagementTab> createState() =>
      _AdminDriverManagementTabState();
}

class _AdminDriverManagementTabState extends State<AdminDriverManagementTab> {
  late Future<_DriverManagementData> _future;
  final Set<String> _busyOrderIds = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant AdminDriverManagementTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _future = _load();
    }
  }

  Future<_DriverManagementData> _load() async {
    var role = normalizeStaffRole(await fetchCurrentStaffRole());
    var managerView = role == 'owner' || role == 'manager';

    // Some owner/admin accounts may not have a normal staff-role row. Preserve
    // legitimate owner access only after a separate database-backed admin check.
    // Empty/unknown role data must never grant manager access by itself.
    if (role.isEmpty) {
      final isDatabaseAdmin = await isCurrentUserAdminFromDatabase();
      if (!isDatabaseAdmin) {
        throw StateError(
          'Delivery staff access could not be verified. Please refresh or sign in again.',
        );
      }
      role = 'owner';
      managerView = true;
    }

    if (managerView) {
      final results = await Future.wait<dynamic>([
        fetchDeliveryDriverOptions(),
        fetchUnassignedDriverOrders(),
        fetchDriverDeliveryTasks(managerView: true),
      ]);

      return _DriverManagementData(
        role: role,
        drivers: results[0] as List<DriverStaffOption>,
        unassigned: results[1] as List<DriverDeliveryTask>,
        tasks: results[2] as List<DriverDeliveryTask>,
      );
    }

    return _DriverManagementData(
      role: role,
      drivers: const <DriverStaffOption>[],
      unassigned: const <DriverDeliveryTask>[],
      tasks: await fetchDriverDeliveryTasks(managerView: false),
    );
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final next = _load();
    setState(() => _future = next);

    try {
      await next;
      if (!mounted) return;
      widget.onChanged();
    } catch (error) {
      // FutureBuilder owns the visible error state. Keep refresh button/pull
      // refresh callbacks from surfacing an uncaught async exception.
      farmDebugLog('Delivery management refresh failed: $error');
    }
  }

  Future<void> _reloadAfterMutation() async {
    // The mutation has already committed before this point. Refresh is
    // deliberately secondary and cannot turn the business action into failure.
    await _reload();
  }

  bool _isOrderBusy(DriverDeliveryTask task) {
    return _busyOrderIds.contains(task.orderId.trim());
  }

  bool _beginOrderMutation(DriverDeliveryTask task) {
    final orderId = task.orderId.trim();
    if (!mounted || orderId.isEmpty || _busyOrderIds.contains(orderId)) {
      return false;
    }

    setState(() => _busyOrderIds.add(orderId));
    return true;
  }

  void _endOrderMutation(DriverDeliveryTask task) {
    final orderId = task.orderId.trim();
    if (orderId.isEmpty) return;

    if (mounted) {
      setState(() => _busyOrderIds.remove(orderId));
    } else {
      _busyOrderIds.remove(orderId);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? FarmColors.danger : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _openFirst(List<String> urls) async {
    for (final value in urls) {
      final clean = value.trim();
      if (clean.isEmpty) continue;
      try {
        if (await openExternalShareUrl(clean)) return true;
      } catch (_) {
        // Try the next fallback.
      }
    }
    return false;
  }

  String _whatsAppPhone(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 7) digits = '1876$digits';
    if (digits.length == 10) digits = '1$digits';
    return digits;
  }

  Future<void> _callCustomer(DriverDeliveryTask task) async {
    final phone = task.customerPhone.trim();
    if (phone.isEmpty) {
      _showMessage('No customer phone number is saved.', error: true);
      return;
    }

    final opened =
        await _openFirst(<String>['tel:${Uri.encodeComponent(phone)}']);
    if (!opened) _showMessage('The phone dialler could not open.', error: true);
  }

  Future<void> _messageCustomer(DriverDeliveryTask task) async {
    final digits = _whatsAppPhone(task.customerPhone);
    if (digits.isEmpty) {
      _showMessage('No customer phone number is saved.', error: true);
      return;
    }

    final message = Uri.encodeComponent(
      'Good day ${task.customerName}, this is The Harvest Place Ja delivery driver regarding order #${task.shortId}.',
    );

    final opened = await _openFirst(<String>[
      'whatsapp://send?phone=$digits&text=$message',
      'https://wa.me/$digits?text=$message',
    ]);

    if (!opened) _showMessage('WhatsApp could not open.', error: true);
  }

  Future<void> _openMaps(DriverDeliveryTask task) async {
    final address = task.deliveryAddress.trim();
    if (address.isEmpty) {
      _showMessage('No delivery address is saved.', error: true);
      return;
    }

    final query = Uri.encodeComponent(address);
    final opened = await _openFirst(<String>[
      'google.navigation:q=$query',
      'https://www.google.com/maps/search/?api=1&query=$query',
    ]);

    if (!opened) _showMessage('Maps could not open.', error: true);
  }

  Future<void> _assign(
    DriverDeliveryTask task,
    List<DriverStaffOption> drivers,
  ) async {
    if (drivers.isEmpty) {
      _showMessage(
        'No active delivery staff are linked to an auth user. Add or link a Delivery staff member first.',
        error: true,
      );
      return;
    }
    if (!_beginOrderMutation(task)) return;

    final requestedDriverId = (task.driverUserId ?? '').trim();
    var selectedDriverId =
        drivers.any((item) => item.userId == requestedDriverId)
            ? requestedDriverId
            : drivers.first.userId;
    final notesController =
        TextEditingController(text: task.managerNotes ?? '');

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  task.assignmentId == null
                      ? 'Assign order #${task.shortId}'
                      : 'Reassign order #${task.shortId}',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedDriverId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Delivery driver',
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                        ),
                        items: drivers
                            .map(
                              (driver) => DropdownMenuItem<String>(
                                value: driver.userId,
                                child: Text(
                                  driver.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedDriverId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Driver instructions (optional)',
                          hintText: 'Gate, landmark, customer preference...',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Assign'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true) return;

      try {
        await assignDriverToDelivery(
          orderId: task.orderId,
          driverUserId: selectedDriverId,
          managerNotes: notesController.text.trim(),
        );
        _showMessage('Driver assigned to order #${task.shortId}.');
        await _reloadAfterMutation();
      } catch (error) {
        _showMessage(friendlyAppError(error), error: true);
      }
    } finally {
      notesController.dispose();
      _endOrderMutation(task);
    }
  }

  Future<void> _unassign(DriverDeliveryTask task) async {
    if (!_beginOrderMutation(task)) return;
    final controller = TextEditingController();

    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Unassign order #${task.shortId}?'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Unassign'),
            ),
          ],
        ),
      );
      if (reason == null) return;

      try {
        await unassignDriverDelivery(orderId: task.orderId, reason: reason);
        _showMessage('Order #${task.shortId} is now unassigned.');
        await _reloadAfterMutation();
      } catch (error) {
        _showMessage(friendlyAppError(error), error: true);
      }
    } finally {
      controller.dispose();
      _endOrderMutation(task);
    }
  }

  Future<void> _setSimpleStatus(
    DriverDeliveryTask task,
    String status,
  ) async {
    if (!_beginOrderMutation(task)) return;

    try {
      await updateDriverDeliveryTask(task: task, status: status);
      _showMessage('Order #${task.shortId}: ${friendlyLabel(status)}.');
      await _reloadAfterMutation();
    } catch (error) {
      _showMessage(friendlyAppError(error), error: true);
    } finally {
      _endOrderMutation(task);
    }
  }

  Future<PickedProductImage?> _pickProofImage() async {
    HpjImageSource source = HpjImageSource.gallery;

    if (!kIsWeb) {
      final selected = await showModalBottomSheet<HpjImageSource>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take proof photo'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    HpjImageSource.camera,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from device'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    HpjImageSource.gallery,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selected == null) return null;
      source = selected;
    }

    return pickProductImageFromDevice(source: source);
  }

  Future<void> _completeDelivery(DriverDeliveryTask task) async {
    if (!_beginOrderMutation(task)) return;

    final recipientController = TextEditingController();
    final noteController = TextEditingController();
    PickedProductImage? proofFile;
    String? uploadedProofPath;
    var deliveryCommitted = false;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Complete order #${task.shortId}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: recipientController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Received by',
                      hintText: 'Customer or recipient name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Delivery note (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        proofFile == null
                            ? Icons.add_a_photo_outlined
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        proofFile == null
                            ? 'Add proof photo'
                            : 'Proof photo selected',
                      ),
                      onPressed: () async {
                        final file = await _pickProofImage();
                        if (file != null) {
                          setDialogState(() => proofFile = file);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the recipient name or attach a proof photo before marking the order delivered.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (recipientController.text.trim().isEmpty &&
                      proofFile == null) {
                    _showMessage(
                      'Enter the recipient name or attach a proof photo.',
                      error: true,
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Mark Delivered'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true) return;

      try {
        if (proofFile != null) {
          uploadedProofPath = await uploadDeliveryProofPhoto(
            orderId: task.orderId,
            image: proofFile!,
          );
        }

        await updateDriverDeliveryTask(
          task: task,
          status: 'delivered',
          driverNotes: noteController.text.trim(),
          proofPhotoPath: uploadedProofPath,
          recipientName: recipientController.text.trim(),
        );
        deliveryCommitted = true;

        _showMessage('Order #${task.shortId} marked delivered.');
        await _reloadAfterMutation();
      } on PostgrestException catch (error) {
        // A PostgREST rejection is an explicit server-side failure, so the RPC
        // transaction did not commit and a newly uploaded proof can be removed.
        // Do not perform this cleanup for ambiguous network/timeout failures.
        if (!deliveryCommitted && uploadedProofPath != null) {
          await deleteDeliveryProofPhoto(uploadedProofPath);
        }
        _showMessage(friendlyAppError(error), error: true);
      } catch (error) {
        // A transport failure can occur after the server committed. Preserve the
        // proof image rather than risk deleting evidence referenced by the order.
        _showMessage(friendlyAppError(error), error: true);
      }
    } finally {
      recipientController.dispose();
      noteController.dispose();
      _endOrderMutation(task);
    }
  }

  Future<void> _reportFailed(DriverDeliveryTask task) async {
    if (!_beginOrderMutation(task)) return;

    final reasonController = TextEditingController();
    final noteController = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Failed delivery #${task.shortId}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Customer unavailable, address issue...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Additional note (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  _showMessage(
                    'Enter a reason for the failed attempt.',
                    error: true,
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save Failed Attempt'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      try {
        await updateDriverDeliveryTask(
          task: task,
          status: 'failed',
          driverNotes: noteController.text.trim(),
          failureReason: reasonController.text.trim(),
        );
        _showMessage('Failed delivery attempt recorded.');
        await _reloadAfterMutation();
      } catch (error) {
        _showMessage(friendlyAppError(error), error: true);
      }
    } finally {
      reasonController.dispose();
      noteController.dispose();
      _endOrderMutation(task);
    }
  }

  Future<void> _reschedule(DriverDeliveryTask task) async {
    if (!_beginOrderMutation(task)) return;

    try {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: now.add(const Duration(days: 1)),
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 90)),
      );
      if (date == null || !mounted) return;

      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );
      if (time == null || !mounted) return;

      final rescheduledFor = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      if (!rescheduledFor.isAfter(DateTime.now())) {
        _showMessage(
          'Choose a delivery date and time that is still in the future.',
          error: true,
        );
        return;
      }

      final noteController = TextEditingController();
      try {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Reschedule order #${task.shortId}'),
            content: TextField(
              controller: noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason or instructions (optional)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Reschedule'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        try {
          await updateDriverDeliveryTask(
            task: task,
            status: 'rescheduled',
            driverNotes: noteController.text.trim(),
            rescheduledFor: rescheduledFor,
          );
          _showMessage(
            'Order #${task.shortId} rescheduled for ${formatCustomerDateTime(rescheduledFor)}.',
          );
          await _reloadAfterMutation();
        } catch (error) {
          _showMessage(friendlyAppError(error), error: true);
        }
      } finally {
        noteController.dispose();
      }
    } finally {
      _endOrderMutation(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DriverManagementData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList();
        }

        if (snapshot.hasError) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              const Header(
                title: 'Delivery & Drivers',
                subtitle: 'Assignments, routes, proof, and delivery status',
              ),
              const SizedBox(height: 18),
              FarmEmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'Driver tools could not load',
                message:
                    '${friendlyAppError(snapshot.error!)}\n\nCheck your connection and access, then try again.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          );
        }

        final data = snapshot.data ??
            const _DriverManagementData(
              role: '',
              drivers: <DriverStaffOption>[],
              unassigned: <DriverDeliveryTask>[],
              tasks: <DriverDeliveryTask>[],
            );

        final activeTasks =
            data.tasks.where((task) => !task.isCompleted).toList();
        final completedTasks =
            data.tasks.where((task) => task.isCompleted).toList();
        final outForDelivery = activeTasks
            .where((task) => task.statusKey == 'out_for_delivery')
            .length;
        final problems = activeTasks
            .where(
              (task) =>
                  task.statusKey == 'failed' || task.statusKey == 'rescheduled',
            )
            .length;

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Header(
                      title: data.managerView
                          ? 'Delivery & Drivers'
                          : 'My Deliveries',
                      subtitle: data.managerView
                          ? 'Assign drivers and monitor every delivery'
                          : 'Customer contact, navigation, proof, and status',
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DriverMetricPill(
                      icon: Icons.assignment_outlined,
                      label: data.managerView ? 'Unassigned' : 'Assigned',
                      value: data.managerView
                          ? '${data.unassigned.length}'
                          : '${activeTasks.length}',
                    ),
                    _DriverMetricPill(
                      icon: Icons.local_shipping_outlined,
                      label: 'On route',
                      value: '$outForDelivery',
                    ),
                    _DriverMetricPill(
                      icon: Icons.report_problem_outlined,
                      label: 'Needs action',
                      value: '$problems',
                    ),
                    _DriverMetricPill(
                      icon: Icons.task_alt_outlined,
                      label: 'Delivered',
                      value: '${completedTasks.length}',
                    ),
                  ],
                ),
              ),
              if (data.managerView) ...[
                const SizedBox(height: 18),
                const _DriverSectionHeading(
                  title: 'Unassigned deliveries',
                  subtitle:
                      'Choose a linked Delivery staff member for each order',
                ),
                const SizedBox(height: 10),
                if (data.unassigned.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'No unassigned deliveries',
                    message:
                        'All active delivery orders currently have a driver.',
                  )
                else
                  ...data.unassigned.map(
                    (task) => _DriverDeliveryCard(
                      task: task,
                      managerView: true,
                      busy: _isOrderBusy(task),
                      onCall: () => _callCustomer(task),
                      onWhatsApp: () => _messageCustomer(task),
                      onMaps: () => _openMaps(task),
                      onAssign: () => _assign(task, data.drivers),
                    ),
                  ),
              ],
              const SizedBox(height: 18),
              _DriverSectionHeading(
                title: data.managerView ? 'Active assignments' : 'Active route',
                subtitle: data.managerView
                    ? 'Monitor drivers and reassign when necessary'
                    : 'Complete each assigned delivery safely',
              ),
              const SizedBox(height: 10),
              if (activeTasks.isEmpty)
                FarmEmptyState(
                  icon: Icons.route_outlined,
                  title: data.managerView
                      ? 'No active driver assignments'
                      : 'No deliveries assigned',
                  message: data.managerView
                      ? 'Assign a driver when a delivery order is ready.'
                      : 'New assigned delivery orders will appear here.',
                )
              else
                ...activeTasks.map(
                  (task) => _DriverDeliveryCard(
                    task: task,
                    managerView: data.managerView,
                    busy: _isOrderBusy(task),
                    onCall: () => _callCustomer(task),
                    onWhatsApp: () => _messageCustomer(task),
                    onMaps: () => _openMaps(task),
                    onAssign: data.managerView
                        ? () => _assign(task, data.drivers)
                        : null,
                    onUnassign: data.managerView ? () => _unassign(task) : null,
                    onAccept: task.canAccept
                        ? () => _setSimpleStatus(task, 'accepted')
                        : null,
                    onStart: task.canStart
                        ? () => _setSimpleStatus(task, 'out_for_delivery')
                        : null,
                    onComplete:
                        task.canComplete ? () => _completeDelivery(task) : null,
                    onFailed: task.canReportProblem
                        ? () => _reportFailed(task)
                        : null,
                    onReschedule:
                        task.canReportProblem ? () => _reschedule(task) : null,
                  ),
                ),
              if (completedTasks.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _DriverSectionHeading(
                  title: 'Recently delivered',
                  subtitle: 'Proof and recipient details for completed orders',
                ),
                const SizedBox(height: 10),
                ...completedTasks.take(10).map(
                      (task) => _DriverDeliveryCard(
                        task: task,
                        managerView: data.managerView,
                        onCall: () => _callCustomer(task),
                        onWhatsApp: () => _messageCustomer(task),
                        onMaps: () => _openMaps(task),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DriverMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DriverMetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: FarmColors.green, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: FarmColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverSectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DriverSectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: FarmColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: FarmColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DriverDeliveryCard extends StatelessWidget {
  final DriverDeliveryTask task;
  final bool managerView;
  final bool busy;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onMaps;
  final VoidCallback? onAssign;
  final VoidCallback? onUnassign;
  final VoidCallback? onAccept;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onFailed;
  final VoidCallback? onReschedule;

  const _DriverDeliveryCard({
    required this.task,
    required this.managerView,
    this.busy = false,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMaps,
    this.onAssign,
    this.onUnassign,
    this.onAccept,
    this.onStart,
    this.onComplete,
    this.onFailed,
    this.onReschedule,
  });

  Color _statusColor() {
    switch (task.statusKey) {
      case 'delivered':
        return FarmColors.success;
      case 'out_for_delivery':
        return FarmColors.green;
      case 'accepted':
        return FarmColors.primary;
      case 'failed':
        return FarmColors.danger;
      case 'rescheduled':
      case 'assigned':
        return FarmColors.warning;
      default:
        return FarmColors.mutedText;
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final clean = value.trim().isEmpty ? 'Not provided' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: FarmColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 13,
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(text: clean),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FarmCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${task.shortId}',
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        task.scheduleText,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(0.22)),
                  ),
                  child: Text(
                    task.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FarmColors.cardSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FarmColors.line),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, 'Customer', task.customerName),
                  _infoRow(Icons.phone_outlined, 'Phone', task.customerPhone),
                  _infoRow(
                    Icons.location_on_outlined,
                    'Address',
                    task.deliveryAddress,
                  ),
                  if (task.deliveryZone.isNotEmpty)
                    _infoRow(Icons.map_outlined, 'Zone', task.deliveryZone),
                  _infoRow(
                    Icons.payments_outlined,
                    'Payment',
                    '${formatPaymentMethod(task.paymentMethod)} • ${task.formattedPayment}',
                  ),
                  _infoRow(
                      Icons.attach_money_rounded, 'Total', task.formattedTotal),
                  if (managerView && task.driverName.isNotEmpty)
                    _infoRow(
                      Icons.local_shipping_outlined,
                      'Driver',
                      task.driverName,
                    ),
                  if ((task.managerNotes ?? '').trim().isNotEmpty)
                    _infoRow(
                      Icons.info_outline,
                      'Instructions',
                      task.managerNotes!,
                    ),
                  if ((task.failureReason ?? '').trim().isNotEmpty)
                    _infoRow(
                      Icons.report_problem_outlined,
                      'Failure reason',
                      task.failureReason!,
                    ),
                  if (task.rescheduledFor != null)
                    _infoRow(
                      Icons.event_repeat_outlined,
                      'Rescheduled',
                      formatCustomerDateTime(task.rescheduledFor!),
                    ),
                  if ((task.recipientName ?? '').trim().isNotEmpty)
                    _infoRow(
                      Icons.verified_user_outlined,
                      'Received by',
                      task.recipientName!,
                    ),
                ],
              ),
            ),
            if (task.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Order items',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              ...task.items.take(6).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${item.productName} × ${item.quantity}',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              if (task.items.length > 6)
                Text(
                  '+${task.items.length - 6} more items',
                  style: const TextStyle(
                    color: FarmColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('Call'),
                ),
                OutlinedButton.icon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('WhatsApp'),
                ),
                OutlinedButton.icon(
                  onPressed: onMaps,
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Navigate'),
                ),
              ],
            ),
            if (busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (onAssign != null ||
                onUnassign != null ||
                onAccept != null ||
                onStart != null ||
                onComplete != null ||
                onFailed != null ||
                onReschedule != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onAssign != null)
                    ElevatedButton.icon(
                      onPressed: busy ? null : onAssign,
                      icon:
                          const Icon(Icons.person_add_alt_1_outlined, size: 18),
                      label: Text(
                        task.assignmentId == null
                            ? 'Assign Driver'
                            : 'Reassign',
                      ),
                    ),
                  if (onUnassign != null)
                    TextButton.icon(
                      onPressed: busy ? null : onUnassign,
                      icon: const Icon(Icons.person_remove_outlined, size: 18),
                      label: const Text('Unassign'),
                    ),
                  if (onAccept != null)
                    ElevatedButton.icon(
                      onPressed: busy ? null : onAccept,
                      icon: const Icon(Icons.task_alt_outlined, size: 18),
                      label: const Text('Accept'),
                    ),
                  if (onStart != null)
                    ElevatedButton.icon(
                      onPressed: busy ? null : onStart,
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text('Start Delivery'),
                    ),
                  if (onComplete != null)
                    ElevatedButton.icon(
                      onPressed: busy ? null : onComplete,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Delivered'),
                    ),
                  if (onFailed != null)
                    OutlinedButton.icon(
                      onPressed: busy ? null : onFailed,
                      icon: const Icon(Icons.report_problem_outlined, size: 18),
                      label: const Text('Failed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FarmColors.danger,
                      ),
                    ),
                  if (onReschedule != null)
                    OutlinedButton.icon(
                      onPressed: busy ? null : onReschedule,
                      icon: const Icon(Icons.event_repeat_outlined, size: 18),
                      label: const Text('Reschedule'),
                    ),
                ],
              ),
            ],
            if ((task.proofPhotoPath ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _DeliveryProofButton(path: task.proofPhotoPath!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeliveryProofButton extends StatefulWidget {
  final String path;

  const _DeliveryProofButton({required this.path});

  @override
  State<_DeliveryProofButton> createState() => _DeliveryProofButtonState();
}

class _DeliveryProofButtonState extends State<_DeliveryProofButton> {
  bool loading = false;

  Future<void> _open() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      final url = await createDeliveryProofSignedUrl(widget.path);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof photo could not be opened.')),
        );
        return;
      }

      final opened = await openExternalShareUrl(url);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof photo could not be opened.')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading ? null : _open,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.photo_camera_back_outlined),
        label: const Text('View Delivery Proof'),
      ),
    );
  }
}
