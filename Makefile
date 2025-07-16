
# Makefile for Fusion 360 Gear Generator Addon

# Fusion 360 file ID for the gear generator
FUSION_FILE_ID := urn:adsk.wipprod:dm.lineage:KdrfgN7NQyWufnPf5J3L0Q

# Path to the Python interpreter in the virtual environment
PYTHON:=FusionHeadless/.venv/bin/python

# Command to run the FusionHeadless script
cli:=$(PYTHON) FusionHeadless/send.py   

# Generates gears with specified parameters.
# Parameters:
# - BORE: Bore diameter in mm
# - HEIGHT: Height of the gear in mm
# - TEETH: Number of teeth on the gear
TEETH:=20 21 22 24 25 26 28 30 32 36 40 42 44 45 48 50 56 60
BORE:=5 6
HEIGHT:=6 9

.PHONY: all open clean
all: \
	open \
	$(foreach h,$(HEIGHT),$(foreach b,$(BORE),$(foreach t,$(TEETH),$(b)B_$(h)H/$(t)T.stl)))

open:
	$(cli) --get /document --data '{"open": "'"$(FUSION_FILE_ID)"'"}'

$(foreach h,$(HEIGHT),$(foreach b,$(BORE),$(foreach t,$(TEETH),$(b)B_$(h)H/$(t)T.stl))): open
	@mkdir -p $(@D)
	$(eval B:=$(subst B, ,$(word 1, $(subst _, ,$(subst /, ,$@)))))
	$(eval H:=$(subst H, ,$(word 2, $(subst _, ,$(subst /, ,$@)))))
	$(eval T:=$(subst T.stl,,$(lastword $(subst /, ,$@))))
	$(eval INTERMEDIATE:=$(subst .stl,.0.stl,$@))
	@echo "Running generation script with BORE=$(B), HEIGHT=$(H), TEETH=$(T)"
	@ $(cli) --get /parameter --data '{"d81":$(T),"d37":$(shell echo $(B) + 0.4 | bc),"emboss-1":$(B),"emboss-0":$(T),"d43":$(shell echo $(H)+1 | bc),"d38":$(shell echo 9.5 + $(H) | bc)}' --silent && \
	$(cli) --get /export --data '{"format": "stl"}' --output $(INTERMEDIATE) --silent && \
	stl_transform -ry 180 $(INTERMEDIATE) $@ && \
	rm $(INTERMEDIATE)


 ######     ###    ########  
##    ##   ## ##   ##     ## 
##        ##   ##  ##     ## 
##       ##     ## ##     ## 
##       ######### ##     ## 
##    ## ##     ## ##     ## 
 ######  ##     ## ########  

CAD/GT2_Pulley.f3d: open
	$(cli) --get /export --data '{"format": "f3d"}' --output $@


#### ##     ##    ###     ######   ########  ######  
 ##  ###   ###   ## ##   ##    ##  ##       ##    ## 
 ##  #### ####  ##   ##  ##        ##       ##       
 ##  ## ### ## ##     ## ##   #### ######    ######  
 ##  ##     ## ######### ##    ##  ##             ## 
 ##  ##     ## ##     ## ##    ##  ##       ##    ## 
#### ##     ## ##     ##  ######   ########  ######  
Images/banner.webp: Images/20T.png Images/30T.png Images/40T.png Images/50T.png Images/60T.png
	@mkdir -p $(@D)
	@echo "Generating banner image..."
	@convert -size 1000x200 xc:white \
		\( Images/20T.png -resize 200x200 \) -geometry +0+0 -composite \
		\( Images/30T.png -resize 200x200 \) -geometry +200+0 -composite \
		\( Images/40T.png -resize 200x200 \) -geometry +400+0 -composite \
		\( Images/50T.png -resize 200x200 \) -geometry +600+0 -composite \
		\( Images/60T.png -resize 200x200 \) -geometry +800+0 -composite \
		$@
Images/%.png:
	@mkdir -p $(@D)
	$(eval B:=5)
	$(eval H:=6)
	$(eval T:=$(subst T.png,,$(lastword $(subst /, ,$@))))
	@echo "Generating image for BORE=$(B), HEIGHT=$(H), TEETH=$(T)"
	@ $(cli) --get /parameter --data '{"d81":$(T),"d37":$(shell echo $(B) + 0.4 | bc),"emboss-1":$(B),"emboss-0":$(T),"d43":$(shell echo $(H)+1 | bc),"d38":$(shell echo 9.5 + $(H) | bc)}' --silent && \
		$(cli) --get /render --data '{"view": "home", "quality": "ShadedWithVisibleEdgesOnly", "width": 400, "height": 400}' --silent --output $@


clean:
	@echo "Cleaning up generated files..."
	@find . -type f -name '*.stl' -exec rm -rf {} + ;
	@find . -type f -name '*.png' -exec rm -rf {} + ;
	@find . -type d -empty -exec rmdir {} \; || true
	@echo "Cleanup complete."