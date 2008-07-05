all:
	./makeinstaller
clean:
	rm -rf build installer.exe
distclean: clean
	rm -rf sources

