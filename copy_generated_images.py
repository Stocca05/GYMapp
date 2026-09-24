import os
import shutil
import glob
import json

src_dir = "/Users/stocca/Library/Developer/Xcode/CodingAssistant/antigravity/antigravity-acp/brain/5678fecb-4c5f-498b-bdf1-d1434f8a047b"
dest_dir = "/Users/stocca/Documents/Programmazione/Frigo/Frigo/Assets.xcassets"

# Map of image prefix to final asset name
asset_names = {
    "pull_ups": "pull_ups_anim",
    "military_press": "military_press_anim",
    "bicep_curl": "bicep_curl_anim",
    "dumbbell_bench": "dumbbell_bench_press_anim",
    "chest_press": "chest_press_anim",
    "seated_press": "seated_press_anim",
    "lateral_raises": "lateral_raises_anim",
    "lat_pulldown": "lat_pulldown_anim",
    "tricep_pushdown": "tricep_pushdown_anim",
    "leg_press": "leg_press_anim",
    "leg_extension": "leg_extension_anim",
    "seated_leg_curl": "seated_leg_curl_anim",
    "calf_press": "calf_press_anim",
    "plank": "plank_anim",
    "bird_dog": "bird_dog_anim"
}

# The images might end in _17XXXXXX.jpg
generated_images = glob.glob(f"{src_dir}/*.jpg")

for img_path in generated_images:
    basename = os.path.basename(img_path)
    # Extract the prefix before the timestamp
    parts = basename.rsplit("_", 1)
    if len(parts) == 2:
        prefix = parts[0]
        if prefix in asset_names:
            asset_name = asset_names[prefix]
            imageset_dir = os.path.join(dest_dir, f"{asset_name}.imageset")
            os.makedirs(imageset_dir, exist_ok=True)
            
            dest_img = os.path.join(imageset_dir, f"{asset_name}.jpg")
            shutil.copy2(img_path, dest_img)
            
            # create Contents.json
            contents = {
                "images": [
                    {
                        "idiom": "universal",
                        "filename": f"{asset_name}.jpg",
                        "scale": "1x"
                    },
                    {
                        "idiom": "universal",
                        "scale": "2x"
                    },
                    {
                        "idiom": "universal",
                        "scale": "3x"
                    }
                ],
                "info": {
                    "author": "xcode",
                    "version": 1
                }
            }
            with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
                json.dump(contents, f, indent=2)
            print(f"Created {asset_name}.imageset")

