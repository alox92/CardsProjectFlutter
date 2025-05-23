#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(
      (GetSystemMetrics(SM_CXSCREEN) - 1280) / 2,
      (GetSystemMetrics(SM_CYSCREEN) - 720) / 2);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Flashcards – Gestionnaire de cartes mémoire", origin, size)) {
    return EXIT_FAILURE;
  }
  // Définir une taille minimale de fenêtre
  window.SetMinimumSize(800, 500);
  // Définir une icône personnalisée (assurez-vous d'avoir une icône dans windows/runner/resources)
  HICON hIcon = (HICON)LoadImage(
      GetModuleHandle(NULL),
      MAKEINTRESOURCE(101), // 101 est l'ID par défaut de l'icône générée par Flutter
      IMAGE_ICON,
      0, 0, LR_DEFAULTSIZE | LR_SHARED);
  if (hIcon) {
    SetClassLongPtr(window.GetHandle(), GCLP_HICON, (LONG_PTR)hIcon);
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
