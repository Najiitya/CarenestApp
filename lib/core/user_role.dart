enum UserRole { caregiver, careReceiver }

extension UserRoleX on UserRole {
  String get key {
    switch (this) {
      case UserRole.caregiver:
        return 'caregiver';
      case UserRole.careReceiver:
        return 'care_receiver';
    }
  }

  static UserRole? fromKey(String? key) {
    switch (key) {
      case 'caregiver':
        return UserRole.caregiver;
      case 'care_receiver':
        return UserRole.careReceiver;
      default:
        return null;
    }
  }
}
