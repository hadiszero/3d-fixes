#!/bin/sh

# Collate all lines between ConstBuffer "$Globals" and the next ConstBuffer or
# BindCB line in the Unity headers among all the given shaders, returning them
# just about ready to use in a HLSL shader.

extract_cb()
{
	awk '/ConstBuffer|BindCB|SetTexture/{f=0} f; /ConstBuffer \"\$Globals\"/{f=1}' "$@"
}

translate_unity_types()
{
	sed 's/^Vector/float4/;s/^Float/float/;s/^Matrix/row_major matrix/'
}

strip_comments()
{
	sed 's/^\/\/\s*//'
}

strip_square_brackets()
{
	sed 's/\[//;s/\]//'
}

byte_offset_to_pack_offset()
{
	awk '{
		offset = int($2 / 16)
		remainder = $2 % 16
		switch (remainder) {
			case 0:
				comp = ""
				break
			case 4:
				comp = ".y"
				break
			case 8:
				comp = ".z"
				break
			case 12:
				comp = ".w"
				break
			default:
				comp = ".???"
				break
		}
		print $1 "|" $3 "|: packoffset(c" offset comp ")"
	}'
}

format()
{
	column -s \| -t | sed 's/^/  /'
}

echo "cbuffer globals : register(b) { // FIXME: register"
extract_cb "$@" | strip_comments | strip_square_brackets | sort -n -k 2 | uniq | byte_offset_to_pack_offset | translate_unity_types | format
echo "}"
