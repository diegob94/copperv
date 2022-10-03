import pyverilog.vparser.ast as vast
from pyverilog.ast_code_generator.codegen import ASTCodeGenerator

def codegen(ast):
    return ASTCodeGenerator().visit(ast)

def ParamWidth(width):
    return vast.Width(vast.Minus(width,vast.IntConst(1)), vast.IntConst(0))

def ReadyValid(prefix,ports):
    if not isinstance(ports,list):
        ports = [ports]
    ready = vast.Input(prefix+'ready')
    valid = vast.Output(prefix+'valid')
    _ports = [ready,valid] + ports
    return vast.Portlist([vast.Ioport(port) for port in _ports])

def Bundle(prefix,ports):
    _ports = []
    for port in ports:
        if isinstance(port,vast.Portlist):
            _ports.extend(p.children()[0] for p in Bundle(prefix,port.children()).children())
            continue
        elif isinstance(port,vast.Ioport):
            port.children()[0].name = prefix + port.children()[0].name
            _ports.append(port.children()[0])
        else:
            port.name = prefix + port.name
            _ports.append(port)
    return vast.Portlist([vast.Ioport(port) for port in _ports])

if __name__ == "__main__":
    data_width = vast.Identifier('data_width')
    addr_width = vast.Identifier('addr_width')
    strobe_width = vast.Divide(addr_width,vast.IntConst(8))
    resp_width = vast.Identifier('resp_width')

    data_addr = [
        vast.Output("data",width=ParamWidth(data_width)),
        vast.Output("addr",width=ParamWidth(addr_width)),
        vast.Output("strobe",width=ParamWidth(strobe_width))
    ]

    ports = Bundle("bus_",[
        Bundle("dr_",[
            ReadyValid("addr_",vast.Output("addr",width=ParamWidth(addr_width))),
            ReadyValid("data_",vast.Input("data",width=ParamWidth(data_width))),
        ]),
        Bundle("dw_",[
            ReadyValid("data_addr_",data_addr),
            ReadyValid("resp_",vast.Input("resp",width=ParamWidth(resp_width)))
        ])
    ])

    print(codegen(ports))

