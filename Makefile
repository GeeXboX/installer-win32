all:
	./makeinstaller
clean:
	rm -rf build geexbox-win32-installer*.exe
distclean: clean
	rm -rf sources

