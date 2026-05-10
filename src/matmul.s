.data #DATA SEGMENT

A: .word 0 3 2 0 3 1 0 3 2 #matrix A
B: .word 1 1 0 3 1 2 0 0 0 #matrix B
C: .word 0 0 0 0 0 0 0 0 0 #matrix C
DIM: .word 3   #matrix dimension
BYTES: .word 4 #bytes per element
LEDS: .word 0x11000020 #led mmio address


.text #TEXT SEGMENT

main: #entry point

# load values from the data segment
la s1, A     #left matrix addr
la s2, B     #right matrix addr
la s3, C     #output matrix addr
la s4, DIM
lw s4, 0(s4) #matrix dimension
la s5, BYTES
lw s5, 0(s5) #data width in bytes
la s9, LEDS
lw s9, 0(s9) #led address

li t0, 1
sw t0, 0(s9) #turn on one led to indicate starting

#calculate stride length
mv a0, s4 #DIM
mv a1, s5 #BYTES
call mult #multiply DIM * BYTES
mv s6, a0 #stride in bytes

#setup row and col indices
mv s7, zero #i column index
mv s8, zero #j row index

matmul: #do the matrix multiplication

#set up the multiplication
mv t5, s1      #copy addr of A
mv a0, s8      #row idx
mv a1, s6      #stride
call mult      #calculate row offset
add t5, t5, a0 #go to the correct row

mv t2, s2      #copy addr of B
mv a0, s7      #col idx
mv a1, s5      #data width
call mult      #calculate col offset
add t2, t2, a0 #go to the correct column

mv t3, zero     #zero a reg for dot products
mv t4, zero     #zero a reg for loop counter (k)

dot:
lw a0, 0(t5)     #load the element from A
lw a1, 0(t2)     #load the element from B
call mult        #multiply the elements from A and B
add t3, t3, a0   #add the result of mult to the dot product

add t5, t5, s5   #go across the row of A (by 1 * BYTES) 
add t2, t2, s6   #go down the column of B (by DIM * BYTES)
addi t4, t4, 1   #increment the loop counter
bltu t4, s4, dot #check the loop condition

sw t3, 0(s3)     #store the dot product in matrix C
add s3, s3, s5   #advance the write pointer for C to the next element

next_col:
addi s7, s7, 1      #advance the col idx
bltu s7, s4, matmul #repeat for the next output element

next_row:
addi s8, s8, 1      #advance the row idx
mv s7, zero         #reset the column idx
bltu s8, s4, matmul #repeat for the next output element
j exit            #the calculation is done, exit

mult: #multiply a0 and a1, return in a0 (assumes unsigned int)

    mult_init: #init a register for the product
    mv t0, zero
    beqz a0, mult_exit
    beqz a1, mult_exit

    mult_loop: #repeatedly add a0, a total of a1 times.
    add t0, t0, a0
    addi a1, a1, -1
    bnez a1, mult_loop

    mult_exit: #place the product in the return register
    mv a0, t0
    ret

exit:
li t0, -1
sw t0, 0(s9) #write all 1 to the LEDS to indicate completion
nop #do nothing on exit
