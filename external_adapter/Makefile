.PHONY : all
all: build/moving_median.zkey moving_median.dat

build/moving_median.zkey moving_median.dat : venv/bin/activate
	. venv/bin/activate && pip install -r requirements.txt
	. venv/bin/activate && cd ../verimedian && pip install -r requirements.txt
	cd ../verimedian && make circuits
	cp ../verimedian/build/moving_median_cpp/moving_median.dat .
	cp ../verimedian/build/moving_median.zkey ./build

venv/bin/activate: requirements.txt
	python -m venv venv

.PHONY : clean
clean :
	rm -rf ./venv
	rm moving_median.dat
	rm ./build/*

docker : Dockerfile ./endpoints/* app.py openapi.yaml
	docker build -t verimedian_adapter:0.1.0 .