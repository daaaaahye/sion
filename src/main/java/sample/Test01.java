package sample;
import java.util.ArrayList;
import java.util.List;

class Test01 {
	private List<String[]> aaa = new ArrayList<String[]>();
	
	Test01() {
		
	}

	public List<String[]> get() {
		String str1[] = {"1","A01","A02","A03","A04"};
		String str2[] = {"2","B01","B02","B03","B04"};
		String str3[] = {"3","C01","C02","C03","C04"};
		String str4[] = {"4","D01","D02","D03","D04"};
		String str5[] = {"5","E01","E02","E03","E04"};

		aaa.add(str1);
		aaa.add(str2);
		aaa.add(str3);
		aaa.add(str4);
		aaa.add(str5);

		return aaa;
	}
}