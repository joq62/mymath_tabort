%% This is the application resource file (.app file) for the 'base'
%% application.
{application, mymath,
[{description, "mymath  " },
{vsn, "1.0.0" },
{modules, 
	  [mymath_app,mymath_sup,mymath]},
{registered,[mymath]},
{applications, [kernel,stdlib]},
{mod, {mymath_app,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/mymath.git"},
{constraints,[{host,h201@c100}]}  %{hw,hw_spec}|{port,port_num}
]}.
