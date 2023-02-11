module testbench();
    typedef struct packed {
      int A; 
      int B; 
      int C;
    } ABC;

    import "DPI-C" function void add1struct(input ABC inp, output ABC result);
    import "DPI-C" function void add1(input int x, output int y);

    ABC data;
    ABC result;
    int y;
    initial begin
        $display("hello");
        data.A = 100;
        data.B = 100;
        data.C = 100;
        add1struct(data,result);
        add1(100,y);
        $display("add1(100) = %0d",y);
        $display("result.A = %0d",result.A);
        $display("result.B = %0d",result.B);
        $display("result.C = %0d",result.C);
        $finish();
    end
endmodule
