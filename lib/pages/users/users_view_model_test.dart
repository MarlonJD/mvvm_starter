import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_starter/auth/user.dart';
import 'package:mvvm_starter/auth/user_service.dart';
import 'package:mvvm_starter/pages/users/users_view_model.dart';

class FakeUserService extends Fake implements UserService {
  bool deleteAllUsersCalled = false;
  User? deletedUser;

  @override
  void deleteAllUsers() {
    deleteAllUsersCalled = true;
  }

  @override
  void deleteUser(User user) {
    deletedUser = user;
  }
}

void main() {
  late UsersViewModel viewModel;
  late FakeUserService fakeUserService;

  setUp(() {
    fakeUserService = FakeUserService();
    viewModel = UsersViewModel(userService: fakeUserService);
  });

  group('UsersViewModel', () {
    test('getAllUsers returns list of users', () {
      viewModel.getAllUsers();

      expect(viewModel.usersNotifier.value.length, 2);
      expect(viewModel.usersNotifier.value[0].name, 'Test User');
      expect(viewModel.usersNotifier.value[1].name, 'Test User 2');
    });

    test('deleteAllUsers calls service', () {
      viewModel.deleteAllUsers();

      expect(fakeUserService.deleteAllUsersCalled, true);
    });

    test('deleteUser calls service with correct user', () {
      final user = User(id: 1, name: 'Test', uid: 'test', isAdmin: 0);

      viewModel.deleteUser(user);

      expect(fakeUserService.deletedUser, user);
    });
  });
}
