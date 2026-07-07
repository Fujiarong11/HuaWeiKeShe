/**
 * LazyForEach 数据源基类
 * 实现 IDataSource 接口，提供高效列表渲染能力
 */

export class BasicDataSource<T> implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private dataArray: T[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): T {
    return this.dataArray[index];
  }

  public getItem(index: number): T {
    return this.dataArray[index];
  }

  public registerDataChangeListener(listener: DataChangeListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  public unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 通知所有监听器数据重载
   */
  public notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }

  /**
   * 通知数据添加
   */
  public notifyDataAdd(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(index);
    });
  }

  /**
   * 通知范围数据添加
   */
  public notifyDataAddRange(start: number, count: number): void {
    if (count > 0) {
      for (let i = start; i < start + count; i++) {
        this.notifyDataAdd(i);
      }
    }
  }

  /**
   * 通知数据变更
   */
  public notifyDataChange(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataChange(index);
    });
  }

  /**
   * 通知数据删除
   */
  public notifyDataDelete(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataDelete(index);
    });
  }

  /**
   * 添加单条数据
   */
  public pushData(data: T): void {
    this.dataArray.push(data);
    this.notifyDataAdd(this.dataArray.length - 1);
  }

  /**
   * 在头部插入数据
   */
  public unshiftData(data: T): void {
    this.dataArray.unshift(data);
    this.notifyDataReload();
  }

  /**
   * 追加数据数组
   */
  public appendData(newData: T[]): void {
    const start = this.dataArray.length;
    this.dataArray = this.dataArray.concat(newData);
    for (let i = start; i < this.dataArray.length; i++) {
      this.notifyDataAdd(i);
    }
  }

  /**
   * 重载全部数据
   */
  public reloadData(newData: T[]): void {
    this.dataArray = newData;
    this.notifyDataReload();
  }

  /**
   * 删除指定索引数据
   */
  public deleteData(index: number): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray.splice(index, 1);
      this.notifyDataDelete(index);
    }
  }

  /**
   * 更新指定索引数据
   */
  public updateData(index: number, data: T): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray[index] = data;
      this.notifyDataChange(index);
    }
  }

  /**
   * 获取所有数据（不触发通知）
   */
  public getAllData(): T[] {
    return this.dataArray;
  }

  /**
   * 清空所有数据
   */
  public clearData(): void {
    this.dataArray = [];
    this.notifyDataReload();
  }

  /**
   * 查找数据索引，通过比较函数
   */
  public findIndex(predicate: (item: T) => boolean): number {
    return this.dataArray.findIndex(predicate);
  }

  /**
   * 查找数据，通过比较函数
   */
  public find(predicate: (item: T) => boolean): T | undefined {
    return this.dataArray.find(predicate);
  }

  /**
   * 判断是否为空
   */
  public isEmpty(): boolean {
    return this.dataArray.length === 0;
  }

  /**
   * 获取数据数组的只读副本
   */
  public getDataArray(): ReadonlyArray<T> {
    return this.dataArray;
  }
}
