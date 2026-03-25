import 'package:management_system_ui/core/common_libs.dart';
import 'invitation_repository.dart';
import 'package:management_system_ui/core/models/store_model.dart';
import 'models/role_model.dart';
import 'models/invitation_response_model.dart';

final tiendasProvider = FutureProvider<List<StoreModel>>((ref) async {
  final repository = ref.watch(invitationRepositoryProvider);
  return repository.getTiendas();
});

final rolesProvider = FutureProvider<List<RoleModel>>((ref) async {
  final repository = ref.watch(invitationRepositoryProvider);
  return repository.getRoles();
});

class InvitationState {
  final bool isLoading;
  final String? errorMessage;
  final InvitationResponseModel? invitationData;
  final String? invitationLink;

  const InvitationState({
    this.isLoading = false,
    this.errorMessage,
    this.invitationData,
    this.invitationLink,
  });

  bool get isSuccess => invitationLink != null;

  InvitationState copyWith({
    bool? isLoading,
    String? errorMessage,
    InvitationResponseModel? invitationData,
    String? invitationLink,
  }) {
    return InvitationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      invitationData: invitationData ?? this.invitationData,
      invitationLink: invitationLink ?? this.invitationLink,
    );
  }
}

class InvitationNotifier extends Notifier<InvitationState> {
  late final InvitationRepository _repository;

  @override
  InvitationState build() {
    _repository = ref.watch(invitationRepositoryProvider);
    return const InvitationState();
  }

  Future<void> enviarInvitacion({
    required String email,
    required int? tiendaId,
    required String rol,
    String salario = '0.00',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.registrarUsuario(
        email: email,
        tiendaId: tiendaId,
        rol: rol,
        salario: salario,
      );

      final link = '${AppConstants.inviteBaseUrl}?token=${response.token}';

      state = state.copyWith(
        isLoading: false,
        invitationData: response,
        invitationLink: link,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const InvitationState();
  }
}

final invitationProvider =
    NotifierProvider<InvitationNotifier, InvitationState>(
  InvitationNotifier.new,
);