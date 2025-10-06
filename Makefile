all: default

demo:
	./odin run examples/demo/demo.odin -file

report:
	./odin report

default:
	PROGRAM=make sh build_odin.sh # debug

debug:
	sh build_odin.sh debug

release:
	sh build_odin.sh release

release-native:
	sh uild_odin.sh release-native

release_native:
	sh build_odin.sh release-native

nightly:
	sh build_odin.sh nightly
