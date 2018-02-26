
CC = csc
FLAGS = 
SRC = $(shell find $(SRC_DIR) -type f | egrep "*.scm" )
SRC_DIR = src
OBJ_DIR = obj
OUT = wyvern
OBJS = $(patsubst %, $(OBJ_DIR)/%.o, $(notdir $(basename $(SRC))))


.PHONY : $(OBJS)

all: $(OBJS)
	$(CC) $^ -o $(OUT)

$(OBJS) : 
	$(CC) -c $(shell find $(SRC_DIR) -type f -name $(notdir $(basename $@ )).scm) -o $@
	
rebuild: clean all
	@echo ""

clean: 
	-rm obj/* || rm $(OUT) rm || generated/*
