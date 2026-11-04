/// A company the central sign-in named (`POST /workspace/sign-in`).
/// [apiHost] is only sent for the company being handed off to.
class WorkspaceTenant {
  final String id;
  final String name;

  /// The host a person reads (the web's frontend host).
  final String host;

  /// The API host every request of the session goes to (`domains.domain`).
  final String? apiHost;

  const WorkspaceTenant({required this.id, required this.name, required this.host, this.apiHost});

  factory WorkspaceTenant.fromJson(Map<String, dynamic> json) {
    final apiHost = json['api_host']?.toString();
    return WorkspaceTenant(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['host'] ?? '').toString(),
      host: (json['host'] ?? '').toString(),
      apiHost: apiHost == null || apiHost.isEmpty ? null : apiHost,
    );
  }
}

/// The two answers of `POST /workspace/sign-in`:
/// - **handoff** — one company matched: [tenant] (with `api_host`) and a
///   single-use [handoffToken] to redeem on that host within 60 s;
/// - **choose** — the email and password open several companies: [tenants]
///   to pick from, then sign in again with the picked `tenant_id`.
class WorkspaceSignInResult {
  static const modeHandoff = 'handoff';
  static const modeChoose = 'choose';

  final String mode;
  final WorkspaceTenant? tenant;
  final String? handoffToken;
  final List<WorkspaceTenant> tenants;

  const WorkspaceSignInResult({required this.mode, this.tenant, this.handoffToken, this.tenants = const []});

  bool get isHandoff => mode == modeHandoff;
  bool get isChoose => mode == modeChoose;

  /// Parses the response's `data`. An answer that is neither a complete
  /// handoff nor a choice throws a [FormatException] with a readable message.
  factory WorkspaceSignInResult.fromJson(Map<String, dynamic> data) {
    final mode = data['mode']?.toString();
    if (mode == modeHandoff) {
      final tenant = data['tenant'] is Map ? WorkspaceTenant.fromJson(Map<String, dynamic>.from(data['tenant'])) : null;
      final token = data['handoff_token']?.toString() ?? '';
      if (tenant == null || tenant.apiHost == null || token.isEmpty) {
        throw const FormatException('The sign-in answer is missing the company or its sign-in link.');
      }
      return WorkspaceSignInResult(mode: modeHandoff, tenant: tenant, handoffToken: token);
    }
    if (mode == modeChoose) {
      final list = data['tenants'] is List ? data['tenants'] as List : const [];
      final tenants = list.whereType<Map>().map((t) => WorkspaceTenant.fromJson(Map<String, dynamic>.from(t))).toList();
      if (tenants.isEmpty) throw const FormatException('The sign-in answer lists no company to choose from.');
      return WorkspaceSignInResult(mode: modeChoose, tenants: tenants);
    }
    throw FormatException('Unexpected sign-in answer (mode: ${mode ?? 'none'}).');
  }
}
