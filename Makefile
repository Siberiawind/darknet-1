GPU=0
CUDNN=0
OPENCV=0
OPENMP=0
DEBUG=0

ARCH= -gencode arch=compute_30,code=sm_30 \
      -gencode arch=compute_35,code=sm_35 \
      -gencode arch=compute_50,code=[sm_50,compute_50] \
      -gencode arch=compute_52,code=[sm_52,compute_52]
#      -gencode arch=compute_20,code=[sm_20,sm_21] \ This one is deprecated?

# This is what I use, uncomment if you know your arch and want to specify
# ARCH= -gencode arch=compute_52,code=compute_52

VPATH=./src/:./examples
SLIB=libdarknet.dll
ALIB=libdarknet.lib
EXEC=darknet.exe
OBJDIR=./obj/

CC=cl
CPP=cl
NVCC=nvcc 
AR=ar
ARFLAGS=rcs
OPTS=-Ofast
LDFLAGS= -lm -lpthreadVC2 -L/c/msys64/usr/local/lib
COMMON= -Iinclude/ -Isrc/ -I/c/msys64/usr/local/include/pthread
CFLAGS=-WX -fPIC

ifeq ($(OPENMP), 1) 
CFLAGS+= -fopenmp
endif

ifeq ($(DEBUG), 1) 
OPTS=-O0 -g
endif

CFLAGS+=$(OPTS)

ifeq ($(OPENCV), 1) 
COMMON+= -DOPENCV
CFLAGS+= -DOPENCV
LDFLAGS+= `pkg-config --libs opencv` -lstdc++
COMMON+= `pkg-config --cflags opencv` 
endif

ifeq ($(GPU), 1) 
COMMON+= -DGPU -I$(CUDA_PATH)/include/
CFLAGS+= -DGPU
LDFLAGS+= -L$(CUDA_PATH)/lib64 -lcuda -lcudart -lcublas -lcurand
endif

ifeq ($(CUDNN), 1) 
COMMON+= -DCUDNN 
CFLAGS+= -DCUDNN
LDFLAGS+= -lcudnn
endif

OBJ=gemm.obj utils.obj cuda.obj deconvolutional_layer.obj convolutional_layer.obj list.obj image.obj activations.obj im2col.obj col2im.obj blas.obj crop_layer.obj dropout_layer.obj maxpool_layer.obj softmax_layer.obj data.obj matrix.obj network.obj connected_layer.obj cost_layer.obj parser.obj option_list.obj detection_layer.obj route_layer.obj upsample_layer.obj box.obj normalization_layer.obj avgpool_layer.obj layer.obj local_layer.obj shortcut_layer.obj logistic_layer.obj activation_layer.obj rnn_layer.obj gru_layer.obj crnn_layer.obj demo.obj batchnorm_layer.obj region_layer.obj reorg_layer.obj tree.obj  lstm_layer.obj l2norm_layer.obj yolo_layer.obj iseg_layer.obj image_opencv.obj
EXECOBJA=captcha.obj lsd.obj super.obj art.obj tag.obj cifar.obj go.obj rnn.obj segmenter.obj regressor.obj classifier.obj coco.obj yolo.obj detector.obj nightmare.obj instance-segmenter.obj darknet.obj
ifeq ($(GPU), 1) 
LDFLAGS+= -lstdc++ 
OBJ+=convolutional_kernels.obj deconvolutional_kernels.obj activation_kernels.obj im2col_kernels.obj col2im_kernels.obj blas_kernels.obj crop_layer_kernels.obj dropout_layer_kernels.obj maxpool_layer_kernels.obj avgpool_layer_kernels.obj
endif

# EXECOBJ = $(addprefix $(OBJDIR), $(EXECOBJA))
EXECOBJ = $(EXECOBJA)
# OBJS = $(addprefix $(OBJDIR), $(OBJ))
OBJS = $(OBJ)
DEPS = $(wildcard src/*.h) Makefile include/darknet.h

all: obj backup results $(SLIB) $(ALIB) $(EXEC)
#all: obj  results $(SLIB) $(ALIB) $(EXEC)


$(EXEC): $(EXECOBJ) $(ALIB)
	$(CC) $(COMMON) $(CFLAGS) $^ -o $@ $(LDFLAGS) $(ALIB)

$(ALIB): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

$(SLIB): $(OBJS)
	$(CC) $(CFLAGS) -shared -LD $^ -o $@ $(LDFLAGS)

%.obj: %.cpp $(DEPS)
	$(CPP) $(COMMON) $(CFLAGS) -c $< -o $@

%.obj: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

%.obj: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@

obj:
	mkdir -p obj
backup:
	mkdir -p backup
results:
	mkdir -p results

.PHONY: clean

clean:
	rm -rf $(OBJS) $(SLIB) $(ALIB) $(EXEC) $(EXECOBJ) $(OBJDIR)/*

