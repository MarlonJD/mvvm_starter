import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/core/result/ui_state.dart";

void main() {
  group("Result", () {
    test("success exposes value without an error", () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.errorOrNull, isNull);
    });

    test("failure exposes app error without a value", () {
      const error = AppError.notFound("auth.userNotFound");
      const result = Result<int>.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, error);
    });
  });

  group("UiState", () {
    test("loading and failure states are explicit", () {
      const loading = UiState<String>.loading();
      const failure = UiState<String>.failure(
        AppError.validation("auth.nameRequired"),
      );

      expect(loading.isLoading, isTrue);
      expect(failure.errorOrNull?.type, AppErrorType.validation);
    });
  });
}
