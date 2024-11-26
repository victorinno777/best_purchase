extends Node2D

@onready var table = $UI/Table
@onready var text_edit = $UI/TextEdit
@onready var predict_button = $UI/PredictButton
var cell = preload("res://cell.tscn")

var scaling_is_active = false

var sales_list = {}
var demand_list = {}
var order_list = {}
var price_list = {}
var provider_list = []
var order = []
var provider = []
var sales = []
var demand = []

enum { PROVIDER, SALES, DEMAND }


func _ready():
	load_data("provider1.txt", PROVIDER)
	load_data("provider2.txt", PROVIDER)
	load_data("sales.txt", SALES)
	load_data("demand.txt", DEMAND)
	
	merge_list(sales, sales_list)
	merge_list(demand, demand_list)


func open_file(file_name):
	var file = FileAccess.open("res://input files/" + file_name, FileAccess.READ)
	return file


func load_data(file_name, type):
	var import = open_file(file_name).get_as_text()
	import = import.split("\r\n")
	var splitted = []
	for line in import:
		splitted.append(line.split(","))
		
	match(type):
		PROVIDER:
			provider.append(splitted)
		SALES:
			sales.append(splitted)
		DEMAND:
			demand.append(splitted)


func merge_list(input_list, list):
	for report in input_list:
		for product in report:
			if list.has(product[0]):
				list[product[0]].append(product[1])
			elif product[0] != "Product":
				list[product[0]] = [product[1]]


func predict_sales():
	order = [["Product", "Quantity"]]
	for product in sales_list:
		var new_quantity : float = 0
		for quantity in sales_list[product]:
			new_quantity += int(quantity)
		new_quantity /= sales_list[product].size()
		
		if scaling_is_active:
			new_quantity *= float(text_edit.text)
		
		new_quantity = ceil(new_quantity)
		
		if demand_list.has(product):
			var demand_quantity = float(demand_list[product][0])
			if demand_quantity > new_quantity:
				new_quantity = demand_quantity
		
		order.append([product, new_quantity])
		order_list[product] = new_quantity


func compare_providers():
	var p = 0
	price_list = {}
	for report in provider:
		for product in report:
			if price_list.has(product[0]):# and product[1] < price_list[product[0]][0]:
				price_list[product[0]].append([product[1], p, product[2]])
			else:
				if product[0] != "Product":
					price_list[product[0]] = [[product[1], p, product[2]]]
		p += 1
	
	for product in price_list:
		for j in price_list[product].size():
			for i in price_list[product].size() - 1:
				if price_list[product][i] > price_list[product][i + 1]:
					var temp = price_list[product][i]
					price_list[product][i] = price_list[product][i + 1]
					price_list[product][i + 1] = temp
	
	
func choose_providers():
	var stop
	provider_list = [["Provider", "Product", "Price", "Quantity"]]
	for product in order_list:
		stop = false
		var need = order_list[product]
		var supply
		for price in price_list[product]:
			if int(price[2]) >= need:
				supply = need
				stop = true
			else:
				need -= int(price[2])
				supply = int(price[2])
			provider_list.append(["provider"+str(price[1] + 1), product, price[0], supply])
			if stop:
				break


func draw_array(array):
	for el in table.get_children():
		el.queue_free()
	
	var i = 0
	var j = 0
	for line in array:
		i = 0
		for a in line:
			var label = cell.instantiate()
			table.add_child(label)
			label.text = str(a)
			label.position = label.size * Vector2(i, j)
			i += 1
		j += 1


func _on_order_button_button_down():
	predict_sales()
	draw_array(order)


func _on_provider_button_button_down():
	compare_providers()
	choose_providers()
	draw_array(provider_list)


func _on_check_box_toggled(button_pressed):
	scaling_is_active = button_pressed


func _on_files_item_selected(index):
	match(index):
		0:
			draw_array(provider[0])
		1:
			draw_array(provider[1])
		2:
			draw_array(sales[0])
		3:
			draw_array(demand[0])
