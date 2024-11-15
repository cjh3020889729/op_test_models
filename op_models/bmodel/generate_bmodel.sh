#!/bin/bash

ONNX_MODEL_DIR=""

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


onnx_files=("$ONNX_MODEL_DIR"/*.onnx)
if [ ${#onnx_files[@]} -eq 0 ]; then
	echo "Error: No .onnx files found in the directory $ONNX_MODEL_DIR!"
	exit 1
fi

for onnx_file in "${onnx_files[@]}"
do
	if [ -f "$onnx_file" ]; then
		echo "Processing ONNX file: $onnx_file"
		
		onnx_file_name=$(basename "$onnx_file" .onnx)

		cache_dir=$(mktemp -d)
		echo "Created cache directory: $cache_dir"
		
		mlir_file="$cache_dir/${onnx_file_name}.mlir"
		bmodel_file="$cache_dir/${onnx_file_name}.bmodel"
		
		model_transform.py --model_name $onnx_file_name --model_def $onnx_file --output_names output_data --mlir $mlir_file
		model_deploy.py --mlir $mlir_file --quantize F32 --processor bm1684 --model $bmodel_file

		if [ -f "$bmodel_file" ]; then
			base_dir_name=$(basename "$ONNX_MODEL_DIR")
			new_dir="./$base_dir_name"

			if [ ! -d "$new_dir" ]; then
				mkdir "$new_dir"
				echo "Created new bmodel directory: $new_dir"
			fi

			cp "$bmodel_file" "$new_dir/"
			echo "Copied .bmodel file to: $new_dir"
		else
			echo "Error: No .bmodel file generated in the cache directory."
		fi

		rm -rf "$cache_dir"
		echo "Deleted cache directory: $cache_dir"
		
		find . -maxdepth 1 -type f ! -name "*.sh" -exec rm -f {} \;
		echo "Cleanup completed."
	fi
done





