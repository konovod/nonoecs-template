{% if flag? :release %}
  module Crystal::System::FileDescriptor
    def self.from_stdio(fd)
      console_handle = false
      handle = LibC._get_osfhandle(fd)
      if handle != -1 && handle != -2
        handle = LibC::HANDLE.new(handle)
        # TODO: use `out old_mode` after implementing interpreter out closured var
        old_mode = uninitialized LibC::DWORD
        if LibC.GetConsoleMode(handle, pointerof(old_mode)) != 0
          console_handle = true
          if fd == 1 || fd == 2 # STDOUT or STDERR
            if LibC.SetConsoleMode(handle, old_mode | LibC::ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0
              at_exit { LibC.SetConsoleMode(handle, old_mode) }
            end
          end
        end
      end

      io = IO::FileDescriptor.new(fd, blocking: true)
      # Set sync or flush_on_newline as described in STDOUT and STDERR docs.
      # See https://crystal-lang.org/api/toplevel.html#STDERR
      if console_handle
        io.sync = true
      else
        io.flush_on_newline = true
      end
      io
    end
  end

  @[Link(ldflags: "/ENTRY:wWinMainCRTStartup")]
  @[Link(ldflags: "/SUBSYSTEM:WINDOWS")]
  lib LibCrystalMain
  end

  lib LibC
    fun CommandLineToArgvW(lpCmdLine : LPWSTR, pNumArgs : Int*) : LPWSTR*
    fun LocalFree(hMem : Void*) : Void*
  end

  fun wWinMain(
    hInstance : Void*,
    hPrevInstance : Void*,
    pCmdLine : LibC::LPWSTR,
    nCmdShow : LibC::Int
  ) : LibC::Int
    argv = LibC.CommandLineToArgvW(pCmdLine, out argc)
    wmain(argc, argv)
    ensure
      LibC.LocalFree(argv) if argv
  end
{% end %}
