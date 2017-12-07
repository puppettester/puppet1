class test-helloworld (
	$testvar
)
{
	notify { 'Hello World!':
		message => "Hello World!, $testvar",
	}

}
