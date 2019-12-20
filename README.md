# CameraAI
Đồ án tốt nghiệp VTCA - COTAI - 12/2019

##### Summary Table

|      | |
| ---------- |-------------------|
| **Author**       | Trần Đức Trọng|
| **Title**        | AI Camera |
| **Topics**       | Ứng dụng machine learning trong việc xử lý và dự đoán khuôn mặt trên môi trường di động iOS, công thức chính được sử dụng là công thức tính khoảng cách Euclid (l2distance)|
| **Descriptions** | Sử dụng camera của iPhone, chụp vài tấm hình đồng thời gắn nhãn cho mỗi hình đã chụp. Tiếp theo, train những tấm hình đã chụp thành những vector ảnh dựa vào model có sẵn (đuôi .pb). Cuối cùng, chụp một tấm ảnh mới, tự động dự đoán ra label tương ứng với tấm ảnh vừa chụp.|
| **Links**        | https://github.com/TrongTran95/CameraAI|
| **Framework**    | TensorFlow-experimental (iOS – Cocoapod)|
| **Pretrained Models**  | Sử dụng model đã đã được train sẵn: https://raw.githubusercontent.com/cuonghx2709/SimpleFacenet/master/SimpleFacenet/Tensorflow/Graph/modelFacenet.pb|
| **Datasets**     | Không có|
| **Level of difficulty**|Sử dụng nhanh và dễ dàng, giao diện trực quan.|

##### Một số hình ảnh train với YOLO
![](https://i.imgur.com/koDwGBQ.png)

![](https://i.imgur.com/JMP0GEH.png)


| **Title**      | Camera AI|
| ---------- |-------------------|
| **Team**       | Trần Đức Trọng (ductrongtran.tdt@gmail.com)|
| **Predicting** | Ứng dụng dự đoán khuôn mặt người dựa vào camera trên iPhone.|
| **Data**       | Data chính là những tấm hình được chụp trên camera của iPhone|
| **Features**   | |
| **Models**     | Công thức l2distance và model phân tích khuôn mặt có sẵn|
| **Results**    | Dự đoán nhãn của khuôn mặt vừa chụp được thông qua những khuôn mặt đã được gán nhãn trước đó|
| **Discussion** | |
| **Future**     | Mở rộng data, lấy data bằng cách import hình thông qua nhiều phương thức (hiện tại chỉ thông qua camera chụp). Real time predict. Đánh dấu vùng khuôn mặt trực tiếp trên camera.|
