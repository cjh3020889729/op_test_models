#!/bin/bash

for arg in "$@"
do
	case $arg in
		--onnx_model_dir=*)
			ONNX_MODEL_DIR="${arg#*=}"
			shift
			;;
		*)
			echo "Unknown parameter: $arg"
			exit 1
			;;
	esac
done

if [ ! -d "$ONNX_MODEL_DIR" ]; then
	echo "Error: Directory $ONNX_MODEL_DIR does not exist!"
	exit 1
fi

subdirectories=("$ONNX_MODEL_DIR"/*)
subdirectories=(${subdirectories[@]})
valid_subdirs=()

for subdir in "${subdirectories[@]}"
do
	if [ -d "$subdir" ]; then
		valid_subdirs+=("$subdir")
	fi
done

if [ ${#valid_subdirs[@]} -eq 0 ]; then
	echo "Error: No valid subdirectories found in the directory $ONNX_MODEL_DIR!"
	exit 1
fi

for subdir in "${valid_subdirs[@]}"
do
	echo "Processing subdirectory: $subdir"

	./generate_bmodel.sh --onnx_model_dir="$subdir"
done



