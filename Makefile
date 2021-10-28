ASM = nasm
ASMFLAGS = -f bin
TARGET = srt0

all: $(TARGET)

$(TARGET): $(TARGET).s
	$(ASM) $(ASMFLAGS) -o $(TARGET).o $(TARGET).s 

clean:
	$(RM) $(TARGET).o
