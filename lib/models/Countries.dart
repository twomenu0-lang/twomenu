class Country {
    var code;
    var name;
    List<CountryState>? states;

    Country({this.code, this.name, this.states});

    factory Country.fromJson(Map<String, dynamic> json) {
        return Country(
            code: json['code'],
            name: json['name'],
            states: json['states'] != null ? (json['states'] as List).map((i) => CountryState.fromJson(i)).toList() : null,
        );
    }

    Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = <String, dynamic>{};
        data['code'] = code;
        data['name'] = name;
        if (states != null) {
            data['states'] = states!.map((v) => v.toJson()).toList();
        }

        return data;
    }
}

class CountryState {
    var code;
    var name;

    CountryState({this.code, this.name});

    factory CountryState.fromJson(Map<String, dynamic> json) {
        return CountryState(
            code: json['code'],
            name: json['name'],
        );
    }

    Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = <String, dynamic>{};
        data['code'] = code;
        data['name'] = name;
        return data;
    }
}

