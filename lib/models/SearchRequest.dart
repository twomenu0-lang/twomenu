class SearchRequest {
    List<int>? price;
    List<Map<String,Object>>? attribute;
    String? text;
    String? bestSelling;
    String? onSale;
    String? featured;
    String? newest;
    String? specialProduct;
    int? page;


    SearchRequest({this.price, this.attribute, this.text,this.bestSelling,
    this.onSale,
    this.featured,
    this.newest,
    this.specialProduct});


    Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = <String, dynamic>{};
        if(text!=null && text!.isNotEmpty){
            data['text'] = text;
        }
        if (price != null) {
            data['price'] = price;
        }
        if (attribute != null && attribute!.isNotEmpty) {
            data['attribute'] = attribute;
        }
        if(bestSelling!=null && bestSelling!.isNotEmpty){
            data['Optional_selling']=bestSelling;
        }
        if(onSale!=null && onSale!.isNotEmpty){
            data['on_sale']=onSale;
        }
        if(featured!=null && featured!.isNotEmpty){
            data['featured']=featured;
        }
        if(newest!=null && newest!.isNotEmpty){
            data['newest']=newest;
        }
        if(specialProduct!=null && specialProduct!.isNotEmpty){
            data['special_product']=specialProduct;
        }
        data['page']=page;
        return data;
    }
}


