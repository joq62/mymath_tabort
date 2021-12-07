all:
#	service
	rm -rf ebin/* *~ */*~ ;
	rm -rf balcony my_services service_catalog test_ebin;
#	application
	cp src/*.app ebin;
	erlc -o ebin src/*.erl;
	echo Done
test:
	rm -rf ebin/* test_ebin *~ */*~ ;	
#	test
	mkdir test_ebin;
	cp test_src/*.app test_ebin;
	erlc -o test_ebin test_src/*.erl;
#	common
#	cp ../common/src/*.app ebin;
	erlc -o ebin ../../common/src/*.erl;
#	loader
	cp ../../infra/controller/src/*app ebin;
	erlc -o ebin ../../infra/controller/src/loader.erl;
#	application
	cp src/*.app ebin;
	erlc -o ebin src/*.erl;	
	erl -pa ebin -pa test_ebin\
	    -setcookie cookie\
	    -sname prodtest\
	    -unit_test cookie cookie\
	    -run prod_test start
unit_test:
	rm -rf ebin/* test_ebin *~ */*~ ;
#	test
	mkdir test_ebin;
	cp test_src/*.app test_ebin;
	erlc -o test_ebin test_src/*.erl;
#	common
#	cp ../common/src/*.app ebin;
	erlc -o ebin ../../common/src/*.erl;
#	loader
	cp ../../infra/controller/src/*app ebin;
	erlc -o ebin ../../infra/controller/src/loader.erl;
#	application
	cp src/*.app ebin;
	erlc -o ebin src/*.erl;	
	erl -pa ebin -pa test_ebin\
	    -setcookie cookie\
	    -sname test\
	    -unit_test cookie cookie\
	    -run unit_test start_test test_src/test.config
